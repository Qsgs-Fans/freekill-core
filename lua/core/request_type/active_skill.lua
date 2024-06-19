local RoomScene = require 'ui_emu.RoomScene'

-- 这里就要定义各种状态性质的属性了 参考一下目前的

---@class ReqActiveSkill: RequestHandler
---@field public skill_name string 当前响应的技能名
---@field public prompt string 提示信息
---@field public cancelable boolean 可否取消
---@field public extra_data any 需要另外定义 先any
---@field public pending_skill string
---@field public pendings integer[] 卡牌id数组
---@field public selected_targets integer[] 选择的目标
---@field public
---@field public
---@field public
---@field public
local ReqActiveSkill = RequestHandler:subclass("ReqActiveSkill")

function ReqActiveSkill:initialize(player)
  RequestHandler.initialize(self, player)
  self.scene = RoomScene:new(self)

  self.pendings = {}
  self.selected_targets = {}
end

function ReqActiveSkill:setup()
  -- skillInteraction.sourceComponent = undefined;
  -- RoomScene.updateHandcards();
  -- RoomScene.enableCards(responding_card);
  -- RoomScene.enableSkills(responding_card, respond_play);
  -- autoPending = false;
  -- progress.visible = true;
  -- okCancel.visible = true;
end

return ReqActiveSkill
