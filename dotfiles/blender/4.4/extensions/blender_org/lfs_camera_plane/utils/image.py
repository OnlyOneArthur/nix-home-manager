# SPDX-FileCopyrightText: 2016-2024 Les Fées Spéciales
#
# SPDX-License-Identifier: GPL-3.0-or-later

import bpy
from bpy_extras.node_utils import connect_sockets
import numpy as np


def get_blender_image_pixels(img):
    array = np.empty(len(img.pixels), dtype=np.single)
    img.pixels.foreach_get(array)
    array.resize(img.size[:] + (4,))  # TODO get number of channels
    return array


def set_blender_image_pixels(img, array):
    img.pixels.foreach_set(np.resize(array, img.size[0] * img.size[1] * 4))


def get_selected_images(objects):
    """Get list of images applied to selected objects"""
    images_selected = []
    valid_objects = []

    for obj in objects:
        for slot in obj.material_slots:
            mat = slot.material
            if mat.node_tree is None:
                continue
            for node in mat.node_tree.nodes:
                if (node.type == "TEX_IMAGE"
                        and node.image is not None
                        and node.image not in images_selected):
                    images_selected.append(node.image)
                    valid_objects.append(obj)

    return valid_objects, images_selected


def get_opacity_node_group():
    if 'Opacity Multiplier' in bpy.data.node_groups:
        return bpy.data.node_groups['Opacity Multiplier']

    node_group = bpy.data.node_groups.new('Opacity Multiplier', 'ShaderNodeTree')

    input_node = node_group.nodes.new('NodeGroupInput')
    input_node.location.x = -200.0
    output_node = node_group.nodes.new('NodeGroupOutput')
    output_node.location.x = 200.0
    math_node = node_group.nodes.new('ShaderNodeMath')
    math_node.operation = 'MULTIPLY'

    base_input = node_group.interface.new_socket(name="Base", in_out='INPUT',
                                                 socket_type='NodeSocketFloat')
    multiplier_input = node_group.interface.new_socket(name="Multiplier", in_out='INPUT',
                                                       socket_type='NodeSocketFloat', )
    opacity_output = node_group.interface.new_socket(name="Value", in_out='OUTPUT',
                                                     socket_type='NodeSocketFloat', )

    multiplier_input.default_value = 1.0
    multiplier_input.max_value = 1.0
    multiplier_input.min_value = 0.0

    connect_sockets(math_node.inputs[0], input_node.outputs[0])
    connect_sockets(math_node.inputs[1], input_node.outputs[1])
    connect_sockets(output_node.inputs[0], math_node.outputs[0])

    return node_group


def add_opacity_to_material(mat):
    """Modify material from Import Images as Planes to add opacity slider"""
    node_tree = mat.node_tree
    if "Opacity Multiplier" in node_tree.nodes:
        return
    image_node = next(node for node in node_tree.nodes if node.type == 'TEX_IMAGE')
    mix_shader_node = next(node for node in node_tree.nodes if node.type == 'MIX_SHADER')

    opacity_node = node_tree.nodes.new("ShaderNodeGroup")
    opacity_node.node_tree = get_opacity_node_group()
    opacity_node.label = opacity_node.name = "Opacity Multiplier"
    opacity_node.location = (-245, 425)

    node_tree.links.remove(image_node.outputs['Alpha'].links[0])
    connect_sockets(mix_shader_node.inputs['Fac'], opacity_node.outputs['Value'])
    connect_sockets(opacity_node.inputs[0], image_node.outputs['Alpha'])
