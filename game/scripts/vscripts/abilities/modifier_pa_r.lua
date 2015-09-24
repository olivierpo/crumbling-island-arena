modifier_pa_r = class({})

function modifier_pa_r:OnDestroy()
	if IsServer() then
		self:GetParent():RemoveModifierByName("modifier_invisible")
	end
end

function modifier_pa_r:CheckState()
	local state = {
		[MODIFIER_STATE_INVISIBLE] = true
	}

	return state
end

function modifier_pa_r:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
 
	return funcs
end

function modifier_pa_r:IsHidden()
	return true
end

function modifier_pa_r:GetModifierMoveSpeedBonus_Percentage(params)
	return 100
end