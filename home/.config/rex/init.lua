-- Rex configuration.
--
-- cmd+w on a pi subagent pane hides the pane instead of killing the agent.
-- Subagent panes carry a block label starting with "🤖 " (set by the pi subagent extension).
-- Anything else closes as usual.

local SUBAGENT_PREFIX = "🤖 "

local function is_subagent(block_id)
  local res = rex.session.list_blocks{}
  for _, b in ipairs((res and res.blocks) or {}) do
    if b.block_id == block_id then
      return type(b.label) == "string" and b.label:sub(1, #SUBAGENT_PREFIX) == SUBAGENT_PREFIX
    end
  end
  return false
end

rex.action{
  name  = "close_or_detach",
  title = "Close (detach subagents)",
  description = "Detach a pi subagent pane so the agent keeps running; close anything else.",
  run   = function(ctx, args)
    if ctx.block_id and is_subagent(ctx.block_id) then
      local _, err = rex.session.detach_block{ block_id = ctx.block_id }
      if err ~= nil then error(err, 0) end
      return { detached = ctx.block_id }
    end
    rex.client.queue("client.close")
  end,
}

rex.bind("cmd+w", "close_or_detach")
