FALL_ABILITY = "falling_hero"

Hero = class({}, nil, DynamicEntity)

function Hero:constructor()
    DynamicEntity.constructor(self)

    self.fallSpeed = 0
    self.falling = false
    self.protected = false
    self.invulnerable = false
end

function Hero:SetUnit(unit)
    self.unit = unit
    unit.hero = self
end

function Hero:SetOwner(owner)
    self.owner = owner
    self.unit:SetControllableByPlayer(owner.id, true)
    PlayerResource:SetOverrideSelectionEntity(owner.id, self.unit)
end

function Hero:SetInvulnerable(value)
    self.invulnerable = value
end

function Hero:GetName()
    return self.unit:GetName()
end

function Hero:GetPos()
    return self.unit:GetAbsOrigin()
end

function Hero:GetRad()
    return self.unit:BoundingRadius2D() * 2
end

function Hero:GetHealth()
    return math.floor(self.unit:GetHealth())
end

function Hero:GetGroundHeight(position)
    return GetGroundHeight(position or self:GetPos(), self.unit)
end

function Hero:FindClearSpace(position, force)
    FindClearSpaceForUnit(self.unit, position, force)
end

function Hero:Alive()
    return self.unit:IsAlive()
end

function Hero:FindModifier(name)
    return self.unit:FindModifierByName(name)
end

function Hero:GetFacing()
    return self.unit:GetForwardVector()
end

function Hero:SetPos(pos)
    self.unit:SetAbsOrigin(pos)
end

function Hero:SetFacing(facing)
    self.unit:SetForwardVector(facing)
end

function Hero:SetHealth(health)
    self.unit:SetHealth(math.floor(health))
end

function Hero:EmitSound(sound, location)
    if location then
        EmitSoundOnLocationWithCaster(location, sound, self.unit)
    else
        self.unit:EmitSound(sound)
    end
end

function Hero:StopSound(sound)
    self.unit:StopSound(sound)
end

function Hero:SwapAbilities(from, to)
    self.unit:SwapAbilities(from, to, false, true)
end

function Hero:Damage(source)
    if source == nil then source = self end

    if not self:Alive() or self.protected or self.falling then
        return
    end

    if self.invulnerable and source ~= self then
        return
    end

    local damageTable = {
        victim = self.unit,
        attacker = source.unit,
        damage = 1,
        damage_type = DAMAGE_TYPE_PURE,
    }

    ApplyDamage(damageTable)

    GameRules.GameMode:OnDamageDealt(self, source)
end

function Hero:Heal()
    self.unit:SetHealth(self.unit:GetHealth() + 1)
end

function Hero:HasModifier(modifier)
    return self.unit:HasModifier(modifier)
end

function Hero:FindAbility(name)
    return self.unit:FindAbilityByName(name)
end

function Hero:EnableUltimate(ultimate)
    self.unit:FindAbilityByName(ultimate):SetLevel(1)
end

function Hero:AddNewModifier(source, ability, modifier, params)
    self.unit:AddNewModifier(source.unit, ability, modifier, params)
end

function Hero:RemoveModifier(name)
    self.unit:RemoveModifierByName(name)
end

function Hero:Delete()
    self.unit:RemoveSelf()
    self.destroyed = true
end

function Hero:Hide()
    self.unit:SetAbsOrigin(Vector(0, 0, 10000))
    self.unit:AddNoDraw()
    AddLevelOneAbility(self.unit, "hidden_arena_hero")
end

function Hero:StartFalling()
    self.falling = true
    AddLevelOneAbility(self.unit, FALL_ABILITY)
end

function Hero:Update()
    if self.owner and self.unit and self.owner:IsConnected() then
        local pos = self:GetPos()
        local to = Vector(pos.x, pos.y, 10000)

        local assigned = PlayerResource:GetPlayer(self.owner.id):GetAssignedHero()

        if assigned then
            assigned:SetAbsOrigin(to)
        end
    end
end

-- return true if hero died
function Hero:UpdateFalling()
    if not self:Alive() then
        return false
    end

    self.fallSpeed = self.fallSpeed + 2

    local origin = self:GetPos()
    origin.z = origin.z - self.fallSpeed
    self:SetPos(origin)

    if origin.z < -7000 then
        self.unit:ForceKill(false)
        self.unit:AddNoDraw()
        self:SetPos(origin) -- Killing a hero resets Z

        return true
    end

    return false
end

function Hero:Setup()
    AddLevelOneAbility(self.unit, "arena_hero")
    self.unit:SetAbilityPoints(0)

    local count = self.unit:GetAbilityCount() - 1
    for i = 0, count do
        local ability = self.unit:GetAbilityByIndex(i)

        if ability ~= nil and not ability:IsAttributeBonus() and not ability:IsHidden()  then
            local name = ability:GetName()

            if string.find(name, "sub") then
                ability:SetHidden(true)
            end

            ability:SetLevel(1)
        end
    end
end