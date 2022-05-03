--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

--[[--
Tree structure that is used when drawing scenes imported from the *gltf format.
]]
-- @module menori.ModelNodeTree

local modules = (...):match('(.*%menori.modules.)')

local Node = require (modules .. '.node')
local ModelNode = require (modules .. 'core3d.model_node')
local Mesh = require (modules .. 'core3d.mesh')

local ml = require (modules .. 'ml')
local mat4 = ml.mat4
local vec3 = ml.vec3
local quat = ml.quat

local ModelNodeTree = Node:extend('ModelNodeTree')

local function set_transform(node, v)
      local t = vec3()
      local r = quat(0, 0, 0, 1)
      local s = vec3(1)
      if v.translation or v.rotation or v.scale then
            t:set(v.translation or {0, 0, 0})
            r:set(v.rotation or {0, 0, 0, 1})
            s:set(v.scale or {1, 1, 1})
	elseif v.matrix then
		mat4(v.matrix):decompose(t, r, s)
      end
      node:set_position(t)
      node:set_rotation(r)
      node:set_scale(s)
end

--- init. Takes as arguments a list of nodes and scenes loaded with glTFLoader.
-- @tparam table nodes
-- @tparam table scenes
function ModelNodeTree:init(gltf, shader)
      ModelNodeTree.super.init(self)
      self.meshes = {}
      for i, v in ipairs(gltf.meshes) do
            self.meshes[i] = Mesh(v)
      end

      self.nodes = {}
      for i, v in ipairs(gltf.nodes) do
            local node
            if v.mesh then
                  local mesh = self.meshes[v.mesh + 1]
                  node = ModelNode(mesh, shader)
                  set_transform(node, v)
            else
                  node = Node()
                  set_transform(node, v)
            end
            node.name = v.name
            self.nodes[i] = node
      end
      for i, v in ipairs(gltf.nodes) do
            if v.children then
                  for _, child_index in ipairs(v.children) do
                        local child = gltf.nodes[child_index + 1]
                        v.node:attach(child.node)
                  end
            end
      end

      self.scenes = {}
      for i, v in ipairs(gltf.scenes) do
            local scene_node = Node(v.name)
            for _, i in ipairs(v.nodes) do
                  scene_node:attach(self.nodes[i + 1])
            end
            self.scenes[i] = scene_node
      end

      self.current_scene = self.scenes[1]
      if self.current_scene then
            self.current_scene:update_transform()
            self:attach(self.current_scene)
      end
end

function ModelNodeTree:foreach(fn)
      self.current_scene:foreach(fn)
end

--- Set scene by name.
-- @tparam string name
function ModelNodeTree:set_scene_by_name(name)
      self:remove_childs()
      for _, v in ipairs(self.scenes) do
            if v.name == name then
                  self:attach(v)
                  self.current_scene = v
            end
      end
end

--- Find a node by name.
-- @tparam string name
function ModelNodeTree:find_node(name)
      for _, v in ipairs(self.nodes) do
            if v.name == name then
                  return v.node
            end
      end
end

return ModelNodeTree