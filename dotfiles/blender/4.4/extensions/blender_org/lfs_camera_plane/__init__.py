# SPDX-FileCopyrightText: 2016-2024 Les Fées Spéciales
#
# SPDX-License-Identifier: GPL-3.0-or-later


import bpy
from bpy.app.handlers import persistent
import numpy as np
from bpy_extras.io_utils import ImportHelper
from bpy.props import StringProperty, CollectionProperty, BoolProperty, FloatProperty
import os
import re

from .utils.image import (
    get_blender_image_pixels, set_blender_image_pixels,
    get_selected_images,
    add_opacity_to_material,
)

SELECT_POLL_ERROR = "Select a camera or its plane children"


class CAMERA_OT_Camera_Plane_Add_Opacity(bpy.types.Operator):
    """Add opacity setting to a plane, if it wasn't added before"""
    bl_idname = "camera.camera_plane_add_opacity"
    bl_label = "Add Opacity to Plane"
    bl_options = {'REGISTER', 'UNDO'}

    plane: StringProperty()

    def execute(self, context):
        material = bpy.data.objects[self.plane].active_material
        if material is not None:
            add_opacity_to_material(material)
        return {'FINISHED'}


class CAMERA_OT_Camera_Plane_Group(bpy.types.Operator):
    """Group multiple plane layers from current camera into one"""
    bl_idname = "camera.camera_plane_group"
    bl_label = "Group Selected Planes"
    bl_options = {'REGISTER', 'UNDO'}

    @classmethod
    def poll(cls, context):
        obj = context.active_object

        if obj is None:
            cls.poll_message_set(SELECT_POLL_ERROR)
            return False

        if obj.type == "CAMERA":
            cam = obj
        elif obj.parent is not None and obj.parent.type == "CAMERA":
            cam = obj.parent
        else:
            cls.poll_message_set(SELECT_POLL_ERROR)
            return False

        selected_children = [child for child in cam.children
                             if child.select_get()
                             and "camera_plane_distance" in child
                             and "originals" not in child]
        if len(selected_children) < 2:
            cls.poll_message_set("Select at least two image planes")
            return False
        return True

    def execute(self, context):
        objects = context.selected_objects
        objects = [o for o in objects
                   if "camera_plane_distance" in o
                   and "originals" not in o]
        objects.sort(key=lambda o: o.camera_plane_distance, reverse=True)

        objects, images_to_process = get_selected_images(objects)
        first_obj = objects[-1]
        first_image = images_to_process[-1]

        img_sizes = {image.size[:] for image in images_to_process}
        if len(img_sizes) >= 2:
            self.report({'ERROR'}, "Could not group layers, are they the same size?")
            return {'CANCELLED'}

        # Assume all images have the same size!
        size = first_image.size[:]

        new_image = bpy.data.images.new("grouped." + first_image.name,
                                        size[0], size[1], alpha=True)

        filepath, ext = os.path.splitext(first_image.filepath)
        new_image.filepath = filepath + ".grouped" + ext

        # Create and link object for new image
        new_obj = first_obj.copy()
        new_obj.name = "grouped." + first_obj.name
        new_mesh = first_obj.data.copy()
        new_mesh.name = "grouped." + first_obj.name
        new_mat = new_obj.material_slots[0].material.copy()
        new_mat.name = "grouped." + first_obj.name
        new_obj.data = new_mesh
        new_obj.material_slots[0].material = new_mat
        for coll in first_obj.users_collection:
            coll.objects.link(new_obj)

        # Create and assign image data
        new_image_buff = create_image_buffer(self, size, images_to_process)
        if type(new_image_buff) is set:
            # Error
            return new_image_buff
        set_blender_image_pixels(new_image, new_image_buff)
        image_node = next(
            node for node in new_mat.node_tree.nodes if node.type == 'TEX_IMAGE')
        image_node.image = new_image
        new_image.save()

        # Keep track of data in objects
        originals = []
        for obj in objects:
            obj["original_distance"] = obj.camera_plane_distance
            obj["grouped"] = new_obj
            originals.append(obj)
            for coll in obj.users_collection:
                coll.objects.unlink(obj)
            obj.use_fake_user = True
        new_obj["originals"] = originals
        new_obj["original_distance"] = new_obj.camera_plane_distance

        context.view_layer.objects.active = new_obj

        return {'FINISHED'}


def create_image_buffer(op, size, images_to_process):
    new_image_buff = np.zeros(size + (4,), dtype=np.single)
    for image in images_to_process:
        # Alpha-composite each image from back to front
        image_buff = get_blender_image_pixels(image)
        # Associate alpha...
        if image.alpha_mode == "STRAIGHT":
            image_buff[:, :, :-1] *= image_buff[:, :, -1:]
        try:
            new_image_buff = (new_image_buff
                              * (1.0 - image_buff[:, :, -1:])
                              + image_buff)
        except:
            op.report({'ERROR'}, "Could not group layers")
            return {'CANCELLED'}
    return new_image_buff


class CAMERA_OT_Camera_Plane_Update_Groups(bpy.types.Operator):
    """Recreate layer groups from individual layers if the file could not be found"""
    bl_idname = "camera.camera_plane_update_groups"
    bl_label = "Update Groups"
    bl_options = {'REGISTER', 'UNDO'}

    @classmethod
    def poll(cls, context):
        obj = context.active_object

        if obj is None:
            cls.poll_message_set(SELECT_POLL_ERROR)
            return False

        if obj.type == "CAMERA":
            cam = obj
        elif obj.parent is not None and obj.parent.type == "CAMERA":
            cam = obj.parent
        else:
            cls.poll_message_set(SELECT_POLL_ERROR)
            return False

        for child in cam.children:
            if ("camera_plane_distance" in child
                    and "originals" in child):
                mat = child.material_slots[0].material
                if mat is None:
                    continue
                image_node = next(node for node in mat.node_tree.nodes
                                  if node.type == 'TEX_IMAGE')
                image = image_node.image
                if not image.has_data:
                    return True
        return False

    def execute(self, context):
        planes = get_planes(context.active_object)
        grouped_planes = [p for p in planes if "originals" in p]

        for grouped_plane in grouped_planes:
            originals = grouped_plane["originals"]

            image_node = next(node for node
                              in grouped_plane.material_slots[0].material.node_tree.nodes
                              if node.type == 'TEX_IMAGE')
            image = image_node.image
            if image.has_data:
                continue

            objects, images_to_process = get_selected_images(originals)
            first_image = images_to_process[-1]

            img_sizes = {image.size[:] for image in images_to_process}
            if len(img_sizes) >= 2:
                self.report({'ERROR'}, "Could not group layers, are they the same size?")
                return {'CANCELLED'}

            # Assume all images have the same size!
            size = first_image.size[:]

            # Create and assign image data
            new_image = bpy.data.images.new(image.name,
                                            size[0], size[1], alpha=True)
            new_image.name = image.name  # force rename
            new_image.filepath = image.filepath
            new_image_buff = create_image_buffer(self, size, images_to_process)
            if type(new_image_buff) is set:
                # Error
                continue

            set_blender_image_pixels(new_image, new_image_buff)
            new_image.save()
            node.image = new_image

        return {'FINISHED'}


class CAMERA_OT_Camera_Plane_Ungroup(bpy.types.Operator):
    """Group multiple plane layers from current camera into one"""
    bl_idname = "camera.camera_plane_ungroup"
    bl_label = "Ungroup"
    bl_options = {'REGISTER', 'UNDO'}

    group: StringProperty(options={'HIDDEN'})
    keep_original_distance: BoolProperty(
        name="Keep Original Distance",
        description="Use distance from before grouping, or keep ungrouped planes close together"
    )
    offset: FloatProperty(
        name="Offset", default=0.01, subtype='DISTANCE', unit='LENGTH',
        description="Offset between ungrouped planes if not using original distance"
    )

    def invoke(self, context, event):
        return context.window_manager.invoke_props_dialog(self)

    def execute(self, context):
        for obj in bpy.context.view_layer.objects:
            obj.select_set(False)

        obj = bpy.data.objects[self.group]
        closest_distance = 0
        for i, orig in enumerate(sorted(
                obj['originals'], key=lambda o: o.camera_plane_distance)):
            closest_distance = closest_distance or orig.camera_plane_distance
            if 'original_distance' in orig:
                del orig['original_distance']
            if not self.keep_original_distance:
                # Recalculate plane distance from group
                orig.camera_plane_distance = closest_distance + i * self.offset
                # Delete drivers if they were deleted in the group and copy props
                if obj.animation_data is not None:  # and obj.animation_data.action is not None:
                    for prop in {"location", "scale"}:  # TODO handle rotation?
                        for index in range(3):
                            grp_driver = obj.animation_data.drivers.find(
                                prop, index=index)
                            if grp_driver is None:
                                orig_driver = orig.animation_data.drivers.find(
                                    prop, index=index)
                                if orig_driver is not None:
                                    orig.animation_data.drivers.remove(orig_driver)
                            getattr(orig, prop)[index] = getattr(
                                obj, prop)[index]
                            if prop == "location" and index == 2:
                                getattr(orig, prop)[index] -= i * self.offset
                        # TODO handle animation...

            del orig['grouped']
        for coll in obj.users_collection:
            for orig in obj['originals']:
                coll.objects.link(orig)
                orig.select_set(True)
            coll.objects.unlink(obj)

        context.view_layer.objects.active = orig
        bpy.data.objects.remove(obj)
        return {'FINISHED'}

    def draw(self, context):
        layout = self.layout
        layout.prop(self, "keep_original_distance")
        row = layout.row()
        row.active = not self.keep_original_distance
        row.prop(self, "offset")


def natural_sort_key(s, _nsre=re.compile('([0-9]+)')):
    """Sort a string in a natural way
    https://stackoverflow.com/a/16090640"""
    return [int(text) if text.isdigit() else text.lower()
            for text in _nsre.split(s)]


class CAMERA_OT_Camera_Plane(bpy.types.Operator, ImportHelper):
    """Import a camera plane"""
    bl_idname = "camera.camera_plane_build"
    bl_label = "Import Camera Plane"
    bl_options = {'REGISTER', 'UNDO'}

    # File props
    files: CollectionProperty(type=bpy.types.OperatorFileListElement,
                              options={'HIDDEN', 'SKIP_SAVE'})
    directory: StringProperty(maxlen=1024, subtype='FILE_PATH',
                              options={'HIDDEN', 'SKIP_SAVE'})

    filter_image: BoolProperty(default=True, options={'HIDDEN', 'SKIP_SAVE'})
    filter_movie: BoolProperty(default=True, options={'HIDDEN', 'SKIP_SAVE'})
    filter_folder: BoolProperty(default=True, options={'HIDDEN', 'SKIP_SAVE'})

    scale: FloatProperty(
        name='Scale',
        description='Extra scale applied after calculation',
        default=100.0,
        soft_min=0,
        soft_max=500,
        min=0,
        subtype='PERCENTAGE')
    distance: FloatProperty(
        name='Distance',
        description='Distance from the camera to the farthest plane',
        default=25.0,
        soft_max=1000,
        min=0,
        step=10,
        subtype='DISTANCE',
        unit='LENGTH')
    step: FloatProperty(
        name='Step',
        description='Distance between planes',
        default=0.1,
        soft_max=50,
        min=0,
        step=10,
        subtype='DISTANCE',
        unit='LENGTH')
    reverse_order: BoolProperty(
        name='Reverse order',
        description='Reverse sorting order',
        default=False)

    @classmethod
    def poll(cls, context):
        if context.active_object is not None and context.active_object.type == 'CAMERA':
            return True
        cls.poll_message_set("Active object is not a camera")
        return False

    def build_camera_plane(self, context):
        # Selection Camera
        cam = context.active_object

        files = [os.path.basename(f.name) for f in self.files]
        files.sort(key=natural_sort_key)

        if not self.reverse_order:
            files.reverse()

        imported_planes = []

        for i, f in enumerate(files):
            bpy.ops.image.import_as_mesh_planes(
                files=[{"name": f}],
                directory=self.directory,
                use_transparency=True,
                shader='SHADELESS',
                overwrite_material=False)
            plane = context.active_object
            imported_planes.append(plane)

            # Move plane to camera's collections
            for coll in plane.users_collection:
                coll.objects.unlink(plane)
            for coll in cam.users_collection:
                coll.objects.link(plane)

            # Scale factor: Import images addon imports
            # images with a height of 1
            # this scales it back to a width of 1
            scale_factor = plane.dimensions[0]
            for v in plane.data.vertices:
                v.co /= scale_factor
            plane.parent = cam
            plane.show_wire = True
            plane.matrix_world = cam.matrix_world
            plane.lock_location = (True,) * 3
            plane.lock_rotation = (True,) * 3
            plane.lock_scale = (True,) * 3

            # Multiple planes spacing
            plane.camera_plane_distance = self.distance - i * self.step
            plane.camera_plane_scale = self.scale

            # DRIVERS
            ## LOC X AND Y (shift) ##
            for axis in range(2):
                driver = plane.driver_add('location', axis)

                # Driver type
                driver.driver.type = 'SCRIPTED'

                # Variable DISTANCE
                var = driver.driver.variables.new()
                var.name = "distance"
                var.type = 'SINGLE_PROP'
                var.targets[0].id = plane
                var.targets[0].data_path = '["camera_plane_distance"]'

                # Variable FOV
                var = driver.driver.variables.new()
                var.name = "FOV"
                var.type = 'SINGLE_PROP'
                var.targets[0].id_type = "OBJECT"
                var.targets[0].id = cam
                var.targets[0].data_path = 'data.angle'

                # Variable scale
                var = driver.driver.variables.new()
                var.name = "shift"
                var.type = 'SINGLE_PROP'
                var.targets[0].id = cam
                var.targets[0].data_path = (
                    'data.shift_' + ('x' if axis == 0 else 'y'))

                # Expression
                driver.driver.expression = \
                    "tan(FOV/2) * distance*2 * shift"

            ## DISTANCE ##
            driver = plane.driver_add('location', 2)
            # Driver type
            driver.driver.type = 'SCRIPTED'
            # Variable
            var = driver.driver.variables.new()
            var.name = "distance"
            var.type = 'SINGLE_PROP'
            var.targets[0].id = plane
            var.targets[0].data_path = '["camera_plane_distance"]'

            # Expression
            driver.driver.expression = "-distance"

            ## SCALE X AND Y ##
            for axis in range(2):
                driver = plane.driver_add('scale', axis)

                # Driver type
                driver.driver.type = 'SCRIPTED'

                # Variable DISTANCE
                var = driver.driver.variables.new()
                var.name = "distance"
                var.type = 'SINGLE_PROP'
                var.targets[0].id = plane
                var.targets[0].data_path = '["camera_plane_distance"]'

                # Variable FOV
                var = driver.driver.variables.new()
                var.name = "FOV"
                var.type = 'SINGLE_PROP'
                var.targets[0].id_type = "OBJECT"
                var.targets[0].id = cam
                var.targets[0].data_path = 'data.angle'

                # Variable scale
                var = driver.driver.variables.new()
                var.name = "scale"
                var.type = 'SINGLE_PROP'
                var.targets[0].id = plane
                var.targets[0].data_path = '["camera_plane_scale"]'

                # Expression
                driver.driver.expression = \
                    "tan(FOV/2) * distance*2 * scale/100.0"

            # Alpha in material
            add_opacity_to_material(plane.active_material)

        for plane in imported_planes:
            plane.select_set(True)
        return {'FINISHED'}

    def execute(self, context):
        return self.build_camera_plane(context)


class CAMERA_OT_Camera_Plane_Layers(bpy.types.Operator):
    """Create one view layer per image, to render them separately"""
    bl_idname = "camera.camera_plane_setup_layers"
    bl_label = "Setup Layers"
    bl_options = {'REGISTER', 'UNDO'}

    def execute(self, context):
        sc = context.scene
        sc.render.film_transparent = True
        sc.render.image_settings.file_format = 'OPEN_EXR_MULTILAYER'
        sc.render.image_settings.exr_codec = 'DWAA'

        planes = get_planes(context.active_object, selected=False)

        # Create collections
        for obj in planes:
            coll = bpy.data.collections.new(obj.name)
            coll.objects.link(obj)
            sc.collection.children.link(coll)

        # Create view layers
        for obj in get_planes(context.active_object, selected=False):
            layer = sc.view_layers.new(obj.name)
            for child_coll in layer.layer_collection.children:
                child_coll.exclude = child_coll.name != obj.name
        return {'FINISHED'}


def get_planes(obj, selected=False):
    if obj.type == "CAMERA":
        cam = obj
    elif obj.parent is not None and obj.parent.type == "CAMERA":
        cam = obj.parent

    # Get planes camera's plane children
    planes = [child for child in cam.children if "camera_plane_distance" in child]
    if selected:
        planes_selected = [plane for plane in planes if plane.select_get()]
        if planes_selected:
            planes = planes_selected
    return planes


class CAMERA_OT_Camera_Plane_Space(bpy.types.Operator):
    """Space planes evenly from closest to farthest"""
    bl_idname = "camera.camera_plane_space"
    bl_label = "Space Equally"
    bl_options = {'REGISTER', 'UNDO'}

    def execute(self, context):
        planes = get_planes(context.active_object, selected=True)
        planes.sort(key=lambda p: p.camera_plane_distance)

        low = planes[0].camera_plane_distance
        high = planes[-1].camera_plane_distance
        current = low

        for plane in planes:
            plane.camera_plane_distance = current
            current += (high - low) / max(len(planes) - 1, 1)
            for driver in plane.animation_data.drivers:
                driver.update()

        # Force viewport update
        plane.location.z = plane.location.z
        plane.update_tag(refresh={'OBJECT'})
        context.view_layer.update()

        return {'FINISHED'}


class CAMERA_OT_Camera_Plane_Reverse(bpy.types.Operator):
    """Reverse plane order"""
    bl_idname = "camera.camera_plane_reverse"
    bl_label = "Reverse"
    bl_options = {'REGISTER', 'UNDO'}

    def execute(self, context):
        planes = get_planes(context.active_object, selected=True)
        planes.sort(key=lambda p: p.camera_plane_distance)
        planes_dist = [p.camera_plane_distance for p in planes]
        planes_dist.reverse()

        for plane, plane_dist in zip(planes, planes_dist):
            plane.camera_plane_distance = plane_dist
            # current += (high - low) / max(len(planes) - 1, 1)
            for driver in plane.animation_data.drivers:
                driver.update()
        plane.location.z = plane.location.z
        plane.update_tag(refresh={'OBJECT'})
        context.view_layer.update()

        return {'FINISHED'}


class CAMERA_PT_Camera_Plane(bpy.types.Panel):
    """Creates a Panel to manipulate planes linked to the camera."""
    bl_label = "Camera Plane"
    bl_space_type = 'PROPERTIES'
    bl_region_type = 'WINDOW'
    bl_context = "object"

    @classmethod
    def poll(cls, context):
        obj = context.active_object
        if (obj is not None
            and (obj.type == "CAMERA"
                 or obj.parent is not None
                 and obj.parent.type == "CAMERA"
                 and "camera_plane_distance" in obj)):
            return True
        return False

    def draw_image_row(self, layout, plane, show_scale=False, show_opacity=False, is_grouped=False):
        row = layout.row(align=True)
        split = row.split(align=True)
        row_name = split.row(align=True)
        if not is_grouped:
            row_name.prop(plane, "camera_plane_hide", icon_only=True, emboss=False,
                          icon="RESTRICT_VIEW_ON" if plane.hide_viewport else "RESTRICT_VIEW_OFF")
            row_name.prop(plane, "camera_plane_select", icon_only=True, emboss=False,
                          icon="RESTRICT_SELECT_OFF"
                          if plane.select_get() else "RESTRICT_SELECT_ON")
            # Warn that visibility state is out of sync
            if plane.hide_viewport != plane.hide_render:
                row_name.label(text='', icon='ERROR')
            if 'originals' in plane:
                row_name.prop(plane, "camera_plane_show_group", text="",
                              icon=("DISCLOSURE_TRI_DOWN" if plane.camera_plane_show_group
                                    else "DISCLOSURE_TRI_RIGHT"))
            row_name.label(text=plane.name, translate=False)
            # Warn that plane is grouped, but outside any group...
            if 'originals' not in plane and ('.grouped' in plane.name or 'grouped.' in plane.name):
                row_warning = row_name.row(align=True)
                row_warning.alert = True
                row_warning.label(text='Outside group?', icon='ERROR')
        else:
            row_name.label(text=plane.name, translate=False)

        row_info = split.row(align=True)

        if is_grouped:
            if show_scale or show_opacity:
                split_factor = 1.0 / 3.0 if show_scale and show_opacity else 0.5
                sub_split = row_info.split(factor=split_factor, align=True)
                sub_distance = sub_split.row(align=True)
                sub_props = sub_split.row(align=True)
            else:
                sub_distance = row_info.row(align=True)
            sub_distance.alignment = 'RIGHT'
            sub_distance.label(text="{:.1f} m".format(
                plane.camera_plane_distance), translate=False)
        else:
            sub_props = row_info.row(align=True)
            sub_props.prop(plane, "camera_plane_distance",
                           emboss=True, text="")

        if show_scale:
            sub_props.prop(plane, "camera_plane_scale", emboss=True, text="")
        if show_opacity:
            node_tree = plane.active_material.node_tree
            if "Opacity Multiplier" in node_tree.nodes:
                sub_props.prop(node_tree.nodes['Opacity Multiplier'].inputs[1],
                               "default_value", emboss=True, text="")
            else:
                sub_props.operator(
                    'camera.camera_plane_add_opacity').plane = plane.name

        return plane.hide_viewport != plane.hide_render

    def draw(self, context):
        layout = self.layout
        settings = context.window_manager.camera_plane_settings

        planes = get_planes(context.active_object)

        # Filter based on selection
        if settings.show_selected:
            planes = [p for p in planes if p.select_get()]

        # Sort planes given selected sort type
        if settings.sort_type == 'ALPHABETICAL':
            planes.sort(key=lambda p: natural_sort_key(p.name))
        else:
            planes.sort(key=lambda p: p.camera_plane_distance)

        layout.operator("camera.camera_plane_build", icon='FILE_IMAGE')

        if len(planes) > 0:
            box = layout.box()

            row = box.row()
            row.prop(settings, "show_selected")
            row.prop(settings, "filter", text="", icon="VIEWZOOM")
            row.prop(settings, "sort_type", expand=True, text="")

            row = box.row()
            row.prop(settings, "show_scale")
            row.prop(settings, "show_opacity")

            col = box.column(align=True)
            col.use_property_split = True
            col.use_property_decorate = False
            col.separator()

            # Column labels
            row_labels = col.row()
            split_labels = row_labels.split()
            sub = split_labels.row()
            sub = split_labels.row()
            sub.alignment = 'CENTER'
            if settings.show_scale or settings.show_opacity:
                split_factor = 1.0 / 3.0 if settings.show_scale and settings.show_opacity else 0.5
                sub_split = sub.split(factor=split_factor, align=True)
                sub = sub_split.row()
                sub.alignment = 'CENTER'
                sub.label(text="Distance")
                if settings.show_scale:
                    sub = sub_split.row()
                    sub.alignment = 'CENTER'
                    sub.label(text="Scale")
                if settings.show_opacity:
                    sub = sub_split.row()
                    sub.alignment = 'CENTER'
                    sub.label(text="Opacity")
            else:
                sub.label(text="Distance")

            is_out_of_sync = False
            for plane in planes:
                if settings.filter not in plane.name:
                    continue
                if 'grouped' not in plane:
                    is_out_of_sync = (self.draw_image_row(col, plane,
                                                          settings.show_scale,
                                                          settings.show_opacity)
                                      or is_out_of_sync)
                if 'originals' not in plane or not plane.camera_plane_show_group:
                    continue

                # Display planes inside a group
                plane_box = col.box()
                plane_col = plane_box.column(align=True)
                originals = plane['originals'][:]

                # Sort planes given selected sort type
                if settings.sort_type == 'ALPHABETICAL':
                    originals.sort(
                        key=lambda p: natural_sort_key(p.name))
                else:
                    originals.sort(
                        key=lambda p: p.camera_plane_distance)

                if CAMERA_OT_Camera_Plane_Update_Groups.poll(context):
                    update_row = plane_col.row()
                    update_row.alert = True
                    update_row.operator("camera.camera_plane_update_groups",
                                        icon="FILE_REFRESH")

                for orig in originals:
                    if settings.filter in orig.name:
                        self.draw_image_row(plane_col, orig,
                                            settings.show_scale, settings.show_opacity,
                                            is_grouped=True)
                plane_col.operator(
                    "camera.camera_plane_ungroup").group = plane.name

            box.separator()
            if is_out_of_sync:
                box.label(text='Viewport and render visibility out of sync for some planes',
                          icon='ERROR')

            box.operator("camera.camera_plane_group", icon="GROUP")
            row = box.row(align=True)
            row.operator("camera.camera_plane_space")
            row.operator("camera.camera_plane_reverse")

        if len(planes) > 0:
            layout.separator()
            layout.operator("camera.camera_plane_setup_layers", icon='RENDERLAYERS')


class CameraPlaneSettings(bpy.types.PropertyGroup):
    sort_type: bpy.props.EnumProperty(
        name="Sort Type",
        items=[('ALPHABETICAL', "Alphabetical", "Alphabetical sort", 'SORTALPHA', 1),
               ('DISTANCE', "Distance", "Sort by distance to camera", 'DRIVER_DISTANCE', 2)],
        default='DISTANCE')
    show_selected: bpy.props.BoolProperty(
        name="Selected Only",
        description="Show selected planes only",
        default=False)
    filter: bpy.props.StringProperty(
        name="Plane Filter",
        maxlen=1024,
        options={'TEXTEDIT_UPDATE'})
    show_scale: bpy.props.BoolProperty(
        name="Show Scale",
        description="Show plane scale in the UI",
        default=False)
    show_opacity: bpy.props.BoolProperty(
        name="Show Opacity",
        description="Show plane opacity in the UI",
        default=False)


@persistent
def camera_plane_handler(_self):
    """Regenerate missing groups on file load"""
    if bpy.ops.camera.camera_plane_update_groups.poll():
        bpy.ops.camera.camera_plane_update_groups()


def register():
    def get_select(self):
        return self.select_get()

    def set_select(self, value):
        self.select_set(value)

    bpy.types.Object.camera_plane_select = bpy.props.BoolProperty(
        get=get_select, set=set_select, name="Select",
        description="Select plane"
    )

    def get_hide(self):
        return self.hide_viewport and self.hide_render

    def set_hide(self, value):
        self.hide_viewport = value
        self.hide_render = value

    bpy.types.Object.camera_plane_hide = bpy.props.BoolProperty(
        get=get_hide,
        set=set_hide,
        name="Disable",
        description="Disable plane in both viewport and render"
    )

    def update_distance(self, context):
        # Update planes inside a group
        if "originals" in self:
            for orig in self["originals"]:
                orig.camera_plane_distance = (orig["original_distance"]
                                              + self.camera_plane_distance
                                              - self["original_distance"])

    bpy.types.Object.camera_plane_distance = bpy.props.FloatProperty(
        name="Camera Plane Distance",
        description="Distance to the camera",
        subtype='DISTANCE',
        unit='LENGTH',
        step=10,
        precision=3,
        update=update_distance
    )

    bpy.types.Object.camera_plane_scale = bpy.props.FloatProperty(
        name="Camera Plane Scale",
        description="Extra scale applied after distance calculation",
        default=100.0,
        soft_max=500,
        min=0,
        subtype='PERCENTAGE'
    )

    bpy.types.Object.camera_plane_show_group = bpy.props.BoolProperty(
        default=True
    )

    bpy.utils.register_class(CameraPlaneSettings)
    bpy.types.WindowManager.camera_plane_settings = bpy.props.PointerProperty(
        type=CameraPlaneSettings
    )

    bpy.utils.register_class(CAMERA_PT_Camera_Plane)
    bpy.utils.register_class(CAMERA_OT_Camera_Plane)
    bpy.utils.register_class(CAMERA_OT_Camera_Plane_Add_Opacity)
    bpy.utils.register_class(CAMERA_OT_Camera_Plane_Group)
    bpy.utils.register_class(CAMERA_OT_Camera_Plane_Update_Groups)
    bpy.utils.register_class(CAMERA_OT_Camera_Plane_Ungroup)
    bpy.utils.register_class(CAMERA_OT_Camera_Plane_Layers)
    bpy.utils.register_class(CAMERA_OT_Camera_Plane_Space)
    bpy.utils.register_class(CAMERA_OT_Camera_Plane_Reverse)

    bpy.app.handlers.load_post.append(camera_plane_handler)


def unregister():
    bpy.utils.unregister_class(CAMERA_OT_Camera_Plane)
    bpy.utils.unregister_class(CAMERA_PT_Camera_Plane)
    bpy.utils.unregister_class(CAMERA_OT_Camera_Plane_Add_Opacity)
    bpy.utils.unregister_class(CAMERA_OT_Camera_Plane_Group)
    bpy.utils.unregister_class(CAMERA_OT_Camera_Plane_Update_Groups)
    bpy.utils.unregister_class(CAMERA_OT_Camera_Plane_Ungroup)
    bpy.utils.unregister_class(CAMERA_OT_Camera_Plane_Layers)
    bpy.utils.unregister_class(CAMERA_OT_Camera_Plane_Space)
    bpy.utils.unregister_class(CAMERA_OT_Camera_Plane_Reverse)
    del bpy.types.Object.camera_plane_select
    del bpy.types.Object.camera_plane_hide
    del bpy.types.Object.camera_plane_distance
    del bpy.types.Object.camera_plane_scale
    del bpy.types.Object.camera_plane_show_group
    del bpy.types.WindowManager.camera_plane_settings
    bpy.utils.unregister_class(CameraPlaneSettings)


if __name__ == "__main__":
    register()
