LycanWolf = LycanWolf or class({}, nil, UnitEntity)

function LycanWolf:constructor(round, owner, target, offsetModifier)
    local direction = (target - owner:GetPos()):Normalized()
    direction = Vector(direction.y, -direction.x, 0)
    local pos = owner:GetPos() + direction * 200 * offsetModifier

    getbase(LycanWolf).constructor(self, round, "npc_dota_lycan_wolf1", pos, owner.unit:GetTeamNumber())

    self.owner = owner.owner
    self.hero = owner
    self.size = 128
    self.start = owner:GetPos()
    self.target = target
    self.offsetModifier = offsetModifier
    self.removeOnDeath = false
    self.attacking = nil
    self.collisionType = COLLISION_TYPE_INFLICTOR
    self.startTime = GameRules:GetGameTime()

    self:SetFacing(target - self.start)
    self:AddNewModifier(self.hero, nil, "modifier_lycan_q", { duration = 3 })

    ImmediateEffect("particles/units/heroes/hero_lycan/lycan_summon_wolves_spawn.vpcf", PATTACH_ABSORIGIN, self.unit)
end

function LycanWolf:GetPos()
    return self:GetUnit():GetAbsOrigin()
end

function LycanWolf:CollidesWith(target)
    return self.owner.team ~= target.owner.team
end

function LycanWolf:CollideWith(target)
    local unit = self:GetUnit()

    if not instanceof(target, Projectile) and not unit:IsStunned() and not unit:IsRooted() and not self.attacking then
        local direction = (target:GetPos() - self:GetPos())
        local distance = direction:Length2D()

        ExecuteOrderFromTable({ UnitIndex = unit:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_STOP })

        self:FindModifier("modifier_lycan_q"):SetDuration(0.25, false)
        self:SetFacing(direction:Normalized())
        self.attacking = target
        self.collisionType = COLLISION_TYPE_RECEIVER
        self:EmitSound("Arena.Lycan.HitQ")

        StartAnimation(unit, { duration = 0.25, activity = ACT_DOTA_ATTACK, rate = 2.0 })
    end
end

function LycanWolf:Update()
    getbase(LycanWolf).Update(self)

    if self.falling then
        return
    end

    if self:FindModifier("modifier_lycan_q"):GetRemainingTime() <= 0 then
        if self.attacking and self.attacking:Alive() then
            local distance = (self.attacking:GetPos() - self:GetPos()):Length2D()

            if distance <= 250 then
                self.attacking:Damage(self)
                self:EmitSound("Arena.Lycan.HitQ2")
                self.hero:MakeBleed(self.attacking)
            end
        end

        self:Destroy()
        return
    end

    if self.attacking then
        if self:GetUnit():IsStunned() or self:GetUnit():IsRooted() then
            self.collisionType = COLLISION_TYPE_INFLICTOR
            self.attacking = false
        end

        return
    end

    local direction = self.target - self.start
    local normal = direction:Normalized()
    local currentPosition = self:GetPos() - self.start
    local projected = (currentPosition:Length2D() + 300) * normal

    local progress = projected:Length2D() / direction:Length2D() - 2 -- graph shifting
    local y = (progress * progress) * 256
    local offset = Vector(normal.y, -normal.x) * y * self.offsetModifier
    local result = self.start + projected + offset

    self.i = (self.i or 0) + 1

    if self.i % 5 == 0 then
        ExecuteOrderFromTable({ UnitIndex = self:GetUnit():GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_DIRECTION, Position = result })
    end
end

function LycanWolf:Damage(source)
    self:Destroy()
end