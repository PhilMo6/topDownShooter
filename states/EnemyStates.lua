
local EnemyStates		= {"new","playing","dead"}
EnemyStates.new		= 1
EnemyStates.playing		= 2
EnemyStates.dead		= 3

EnemyStates.update = {}
EnemyStates.draw = {}

EnemyStates.update[1] = function(enemy,dt)
end

EnemyStates.update[2] = function(enemy,dt)
	if enemy.reloading then 
		enemy.reloading = enemy.reloading - dt 
		if enemy.reloading <= 0 then enemy.reloading = nil end
	end
	if enemy.rateOfFire then 
		enemy.rateOfFire = enemy.rateOfFire - dt 
		if enemy.rateOfFire <= 0 then enemy.rateOfFire = nil end
	end
	enemy:move()
	enemy:updateRightAxis()
	if enemy.contact then 
		enemy:mobAttack(enemy.contact)
	end
	enemy.animation:update(dt)
end

EnemyStates.update[3] = function(enemy,dt)
	enemy.respawnTimer = enemy.respawnTimer - dt 
	if enemy.respawnTimer <= 0 then 
		enemy:respawn()
	end
	enemy.animation:update(dt)
end

return EnemyStates
