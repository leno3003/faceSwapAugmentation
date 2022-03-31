#!/usr/bin/python3
'''
Author: Hussein Bakri
License: MIT
Requirements: Blender on the OS (runnable from terminals/Command Lines)
            Package Pillow/Image: sudo pip3 install image in Blender
            You have to install GraphicsMagick (so that the gm command can work)
            Fedora 26: sudo dnf install GraphicsMagick
            Ubuntu: sudo apt-get install graphicsmagick

Usage: blender -b -P GIFandSpriteFromModel.py -- --inm 'Original_Mesh.obj'

'''

import argparse
from math import radians
from math import degrees
from random import uniform, random
import subprocess
import time
import bpy
import bmesh
from bmesh.ops import spin
from mathutils import Euler, Vector, Color
import os
import sys
import numpy as np
#import image
#from PIL import Image
#import Image
#import glob

def get_args():
  parser = argparse.ArgumentParser()
 
  # get all script args
  _, all_arguments = parser.parse_known_args()
  double_dash_index = all_arguments.index('--')
  script_args = all_arguments[double_dash_index + 1: ]
 
  # add parser rules
  parser.add_argument('-in', '--inm', help="Original Model")
  parsed_script_args, _ = parser.parse_known_args(script_args)
  return parsed_script_args


args = get_args()

input_model = str(args.inm)
print(input_model)

print('\n Clearing blender scene (default garbage...)')
# deselect all
bpy.ops.object.select_all(action='DESELECT')

# selection
#bpy.data.objects['Camera'].select = True

# remove it
#bpy.ops.object.delete() 

# Clear Blender scene
# select objects by type
for o in bpy.data.objects:
    if o.type == 'MESH':
        o.select_set(state=True)
    else:
        o.select_set(state=False)

# call the operator once
bpy.ops.object.delete()

def create_point_light(energy, location):
    light_data = bpy.data.lights.new(name="light_2.80", type='POINT')
    light_data.energy = energy

    # create new object with our light datablock
    light_object = bpy.data.objects.new(name="light_2.80", object_data=light_data)
    # link light object
    bpy.context.collection.objects.link(light_object)
    # make it active 
    bpy.context.view_layer.objects.active = light_object
    #change location
    light_object.location = location

create_point_light(2000, (0, -7, 0))
create_point_light(500, (4, -4, 0))
create_point_light(500, (-4, -4, 0))


#importing the OBJ Model
bpy.ops.import_scene.obj(filepath=input_model)
wfobj_vertex_colors, wfobj_face_idx = [], []
with open(input_model, 'r') as file:
    for line in file.readlines():
        if line.startswith('v'):
            v,x,y,z,r,g,b = line.split(' ')
            wfobj_vertex_colors.append((float(r),float(g),float(b)))
        elif line.startswith('f'):
            f,i1,i2,i3 = line.split(' ')
            wfobj_face_idx.append((int(i1),int(i2),int(i3)))
print(len(wfobj_vertex_colors), len(wfobj_face_idx))
#pywf = pywavefront.Wavefront(input_model)
#print(dir(pywf))
#exit(0)
print('\n Obj file imported successfully ...')
print('\n Creating and object list and adding meshes to it ...')
objectList=bpy.data.objects

meshes = []
for obj in objectList:
  if(obj.type == "MESH"):
    meshes.append(obj)

print("{} meshes".format(len(meshes)))

for i, obj in enumerate(meshes):
    if not obj.data.vertex_colors:
        obj.data.vertex_colors.new()
    color_layer = obj.data.vertex_colors.active
    mat = bpy.data.materials.new('Mat1')
    obj.active_material = mat
    #print(dir(mat))
    #mat.use_vertex_color_paint = True
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    mat_links = mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    assert(bsdf) # make sure it exists to continue
    vcol = nodes.new(type="ShaderNodeVertexColor")
    # vcol.layer_name = "VColor" # the vertex color layer name
    vcol.layer_name = "Col"
    mat_links.new(vcol.outputs['Color'], bsdf.inputs['Base Color'])

    print('\n\n')
    print(dir(obj.data))

    #obj.data.materials[0].use_vertex_color_paint = True
    ii = 0
    for face_id, poly in enumerate(obj.data.polygons):
        for vert_id, idx in enumerate(poly.loop_indices):
            r,g,b = wfobj_vertex_colors[ wfobj_face_idx[face_id][vert_id] - 1 ]
            color_layer.data[ii].color = (r, g, b, 1.0)
            ii += 1
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode='VERTEX_PAINT')
    print("{}/{} meshes, name: {}".format(i, len(meshes), obj.name))




scene = bpy.context.scene
fp = os.path.dirname(os.path.realpath(__file__))
#fp = scene.render.filepath # get existing output path
print('\n Saving a .blend file of the scene: ')
print(fp)

scene.render.image_settings.file_format = 'PNG' # set output format to .png

scene = bpy.context.scene
#print(scene.camera.rotation_euler)
#print(scene.camera.location)
#exit(0)

scene.camera.location = (0, -6, 0)
scene.camera.rotation_euler = Euler((radians(90), 0, 0), 'XYZ')
#print(dir(scene.camera))
#exit(0)

print("\n Saving a .blend file of the scene")
bpy.ops.wm.save_as_mainfile(filepath="OBJscene.blend")


#bpy.ops.view3d.dolly()

x_rotation = radians(90)
y_rotation = 0#radians(0)
z_rotation = 0#radians(300)
n = 0
x_total_rotation = radians(5 * 20) / 2
z_total_rotation = radians(5 * 36) / 2

print('\n begin rendering frames: ')
for x_step in np.linspace(-x_total_rotation, x_total_rotation, 7): 
    for z_step in np.linspace(-z_total_rotation, z_total_rotation, 11): 

        # set current frame to frame 5
        scene.frame_set(n)

        # set output path so render won't get overwritten
    
        ob = bpy.context.view_layer.objects.active
        ob.name = 'tree'
        # set the objects rotation
        ob.rotation_euler = Euler((x_rotation + x_step, 
                                   y_rotation, 
                                   z_rotation + z_step
                                   ), 'XYZ')
        scene.render.filepath = fp + "/" + str(n)
        bpy.ops.render.render(write_still=True) # render still
        #z_rotation = z_rotation + radians(5)
        n += 1
    #z_rotation = radians(300)
    #x_rotation = x_rotation + radians(12)


    
# restore the filepath
scene.render.filepath = fp
bpy.ops.wm.quit_blender()
sys.exit(0)
