TestStandard = { setup = FkTest.initRoom, tearDown = FkTest.clearRoom }

-- 暂且在这里读取SkillSkel中包含的测试函数，命名规则另说
-- 后面再好好改改测试代码的实现规则
for _, pname in ipairs(Fk.package_names) do
  local pack = Fk.packages[pname]
  for _, skel in ipairs(pack.skill_skels) do
    for i, fn in ipairs(skel.tests) do
      TestStandard[string.format('test%s%d', skel.name, i)] = function()
        local room = FkTest.room
        fn(room, room.players[1])
      end
    end
  end
end
