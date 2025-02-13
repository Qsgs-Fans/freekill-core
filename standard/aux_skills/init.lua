local prefix = "packages.standard.aux_skills."
if UsingNewCore then
  prefix = "packages.freekill-core.standard.aux_skills."
end

return {
  require(prefix .. "discard_skill"),
  require(prefix .. "choose_cards_skill"),
  -- require(prefix .. "wushuang"),
  -- require(prefix .. "qingnang"),
  -- require(prefix .. "jijiu"),
  -- require(prefix .. "wushuang"),
  -- require(prefix .. "lijian"),
  -- require(prefix .. "biyue"),
}

