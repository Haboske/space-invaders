-- title:   Space survivor
-- author:  Bryan DELAITRE
-- desc:    Survivez
-- site:    website link
-- license: MIT License (change this to your license of choice)
-- version: 0.1
-- script:  lua

t = 0
x = 96
y = 24
player_score = 1
player_dead = false
player_power = 0
player_life = 10000
player_spell = 1
spell_list = {}
spell_timer = 0
spell_duration = 0
spell_particle_list = {}
tank_timer = 0
boss_timer = 0
nb_particule = 0
listO = {}
listP = {}
list_particule = {}
timer = 0
projectile_timer = 0
gamestop = false
chrono = 0


-- We create the function that allow our programm to detect collision between two objects
function CheckCollision(x1,y1,w1,h1, x2,y2,w2,h2)
    -- We compare the position x of the first object with the position x + the width of the second object
    return x1 < x2+w2 and
    -- and etc
    x2 < x1+w1 and
    y1 < y2+h2 and
    y2 < y1+h1
end

-- initObstacle spawn a sprite
function initObstacle(obstacle_type)
    -- we put the sprite created in the list so we can create multiple sprite
    local t={}
    t.type=obstacle_type
    t.x=-8
    -- math.random allow us to randomize a number and, in this case randomize the y position when spawning
    t.y=math.random(0,136-8)
    if obstacle_type == 1 then
        t.height=8
        t.width=8
    elseif obstacle_type == 2 then
        t.l=2 
        t.height=8
        t.width=8  
    elseif obstacle_type == 3 then
        t.l=4
        t.height=16
        t.width=16
        --shooting timer
        t.sT=0
    end
    table.insert(listO,t)
end

-- creating the function that allow the player to spawn a Projectile to destroy the obstacles
function initProjectile(playerX,playerY)
    local p={}
    p.x=playerX
    p.y=playerY
    p.shooter=0
    table.insert(listP,p)
    sfx(03,"B-3",10)
end

function bossProjectile(bossX,bossY)
    local p={}
    p.x=bossX
    p.y=bossY
    p.shooter=3
    table.insert(listP,p)
    sfx(01,"C-1",10)
end

function initSpell()
    local p={}
    if player_spell >= 1 then
        player_spell = player_spell - 1
        p.x=239
        p.y=math.random(0,136-16)
        p.active = true
        table.insert(spell_list,p)
    end
end
  

function initParticule(ennemyX,ennemyY)
    local ptc={}
    ptc.x=ennemyX
    ptc.y=ennemyY
    ptc.vx=math.random(-400,400)/100
    ptc.vy=math.random(-400,400)/100
    ptc.l = math.random(20,80)
    ptc.s = math.random(32,38)
    table.insert(list_particule,ptc)
    sfx(01,"C-3",15)
end

function partSpell(spellY)
    local ptc={}
    ptc.x=math.random(0,239)
    ptc.y=spellY
    ptc.vx=math.random(-400,-1)/15
    ptc.vy=math.random(-50,50)/100
    ptc.l = math.random(200,1000)
    ptc.s = math.random(36,44)
    table.insert(spell_particle_list,ptc)
    sfx(02,"B-1",160)
end




-- we spawn the first obstacle before the TIC function.
initObstacle(1)

-- the function update allow us to update all the data and positions in the game
function update()

    -- btn is the function that allow us to know which key from the keyboard we are pressing
    if btn(0) then y=y-1.5 end
    if btn(1) then y=y+1.5 end
    if btn(2) then x=x-1.5 end
    if btn(3) then x=x+1.5 end

    if btn(4) then
        spell_timer = 180
        initSpell()
    end
    
    -- everytime we call the update function we add one
    timer=timer+1
    if timer>=60 then
        initObstacle(1)
        timer=0
        chrono = chrono + 1
    end

    tank_timer=tank_timer+1
    if tank_timer>=143 then
        initObstacle(2)
        tank_timer = 0
    end

    boss_timer=boss_timer+1
    if boss_timer >= 280 then
        initObstacle(3)
        boss_timer = 0

    end

    projectile_timer=projectile_timer+1
    if projectile_timer>=30 then
        initProjectile(x,y)
        projectile_timer=0
    end

    spell_timer = spell_timer - 1

    -- We create a loop that
    -- pour tous éléments n dans la liste, on vérifie à partir du dernier, et ensuite on passe au précédant
    for n=#listO,1,-1 do
        -- on vient assigner un vecteur au carré qu'on vérifie
        local obstacle=listO[n]
        if obstacle.type == 1 then
            -- on déplace le carré sur le vecteur x
            obstacle.x=obstacle.x+1
        elseif obstacle.type == 2 then
            obstacle.x=obstacle.x+0.75
        elseif obstacle.type == 3 then
            obstacle.x=obstacle.x+0.5
        end

        -- si le carré dépasse la position 240 sur le vécteur x, alors
        if obstacle.x>=240 then
            -- on supprime l'obstacle de la liste
            table.remove(listO,n)
            -- on en recrée un nouveau selon son ancien type
            initObstacle(obstacle.type)
            -- et on retire 1 au score du joueur
            player_score=player_score-1
        end

        -- si, le carré collisionne avec le joueur, alors
        if CheckCollision(x,y,8,8,obstacle.x,obstacle.y,8,8) then
            player_life = player_life - 1
            table.remove(listO,n)
            for countin=40,1,-1 do
                initParticule(obstacle.x,obstacle.y)
            end
        end 
    end

    for n=#listP,1,-1 do
        -- on vient assigner un vecteur au projectile qu'on vérifier
        local projectile=listP[n]
        if projectile.shooter == 0 then
            if player_score < 5 then
                -- on déplace horizontalement le projectile vers la gauche
                projectile.x=projectile.x-1
                player_power = 0
            elseif player_score >= 5 and player_score < 15 then
                projectile.x = projectile.x-3
                player_power = 1
            elseif player_score >= 15 then
                projectile.x = projectile.x-5
                player_power = 2
            end
        elseif projectile.shooter == 3 then
            projectile.x = projectile.x+2
        end

        -- quand le projectile sort de la map
        if projectile.x<=0 and projectile.shooter == 0 then
            -- on le supprime de la liste des projectile
            table.remove(listP,n)
        end

        if projectile.x>=250 and projectile.shooter == 3 then
            table.remove(listP,n)
        end

        if projectile.shooter == 3 then
            if CheckCollision(x,y,8,8,projectile.x,projectile.y,8,16) then
                table.remove(listP,n)
                player_life = player_life - 1
            end
        end 

        -- pour chaque balle on vient vérifier chaque carré présent
        for nO=#listO,1,-1 do
            
            if projectile.shooter == 0 then
                local obstacle=listO[nO]

                if obstacle.type == 3 then
                    obstacle.sT = obstacle.sT + 1
                    if obstacle.sT >= 60 then
                        bossProjectile(obstacle.x,obstacle.y)
                        obstacle.sT = 0
                    end
                end
                -- si une balle touche un carré alors on ajoute un point
                if CheckCollision(projectile.x,projectile.y,8,8,obstacle.x,obstacle.y,obstacle.width,obstacle.height) then
                    -- on va checker de quel type d'obstacle il s'agit (un simple "1", ou un costaud "2")
                    if obstacle.type == 1 then
                        -- on crée une quarantaine de particule pour l'effet de destruction
                        for countin=40,1,-1 do
                            initParticule(obstacle.x,obstacle.y)
                        end
                        -- on le supprime de la liste
                        table.remove(listO,nO)
                        player_score = player_score + 1
                    elseif obstacle.type == 2 then
                        -- on lui retire 1 point de vie
                        obstacle.l=obstacle.l-1
                        -- si il n'a plus de vie alors
                        if obstacle.l <=0 then
                            table.remove(listO,nO)
                            for adjNB=#listO,1,-1 do
                                local obstacle_adjacent=listO[adjNB]
                                if CheckCollision(obstacle.x-30,obstacle.y-30,60,60,obstacle_adjacent.x,obstacle_adjacent.y,8,8) then
                                    table.remove(listO,adjNB)
                                    for countin=40,1,-1 do
                                        initParticule(obstacle_adjacent.x,obstacle_adjacent.y)
                                    end
                                    player_score=player_score+1
                                end
                            end
                            for countin=40,1,-1 do
                                initParticule(obstacle.x,obstacle.y)
                            end
                        end
                        player_score = player_score + 2
                    elseif obstacle.type == 3 then
                        obstacle.l = obstacle.l-1
                        if obstacle.l <= 0 then
                            for countin=100,1,-1 do
                                initParticule(obstacle.x,obstacle.y)
                            end
                            table.remove(listO,nO)
                            if player_spell < 1 then
                                player_spell = player_spell + 1                
                            end
                        end
                        player_score = player_score + 10
                    end
                    -- on retire le projectile et l'obstacle de leur listes respective
                    table.remove(listP,n)
                end
            end

        end
    end

    for sP=#spell_list,1,-1 do
        local spell=spell_list[sP]
        if spell.active == true and spell_duration <= 180 then
            for sPo=#listO,1,-1 do
                local obstacle_spell = listO[sPo]
                if CheckCollision(obstacle_spell.x,obstacle_spell.y,obstacle_spell.width,obstacle_spell.height,0,spell.y-30,239,60) then
                    for countin=40,1,-1 do
                        initParticule(obstacle_spell.x,obstacle_spell.y)
                    end
                    table.remove(listO,sPo)
                end
            end
            for countin=10,1,-1 do
                partSpell(spell.y)
            end
            spell_duration = spell_duration + 1
        elseif spell_duration > 180 then
            spell.active = false
            spell_duration = 0
            table.remove(spell_list,sP)
        end
    end

    for nPtc=#list_particule,1,-1 do
        local ptc=list_particule[nPtc]
        ptc.x=ptc.x+ptc.vx
        ptc.y=ptc.y+ptc.vy
        ptc.l=ptc.l-1
        if ptc.l >= 1 then
            ptc.l=ptc.l-math.random(1,5)
        else
            table.remove(list_particule,nPtc)
        end
    end

    for nPtc=#spell_particle_list,1,-1 do
        local ptc = spell_particle_list[nPtc]
        ptc.x=ptc.x+ptc.vx
        ptc.y=ptc.y+ptc.vy
        ptc.l=ptc.l-1
        if ptc.l >= 1 then
            ptc.l=ptc.l-math.random(1,5)
        else
            table.remove(spell_particle_list,nPtc)
        end
    end

    -- si le score ou le chrono dépasse la limite imposé
    if player_score<=0 or chrono >= 60 or player_life <= 0 then
        if player_life == 0 then
            player_dead = true
        end
        -- on arrête la partie
        gamestop=true
    end 
end
  
-- la fonction draw permet de générer les visuels sur notre console
function draw()
    -- on clear la console
    cls(0)
    
    -- on génère le joueur
    spr(1,x,y,0)

    -- pour n qui démarre a 1, on check les éléments du tableau
    for n=1,#listO do
        -- on récupère la position de l'obstacle
        local obstacle=listO[n]
        -- on génère le sprite
        if obstacle.type == 1 then
            spr(16,obstacle.x,obstacle.y,0)
        elseif obstacle.type == 2 then
            spr(17,obstacle.x,obstacle.y,0)
            if obstacle.l == 2 then
                spr(65,obstacle.x-6,obstacle.y,0)
            elseif obstacle.l == 1 then
                spr(67,obstacle.x-6,obstacle.y,0)
            end
        elseif obstacle.type == 3 then
            spr(18,obstacle.x,obstacle.y,0)
            spr(19,obstacle.x,obstacle.y+8,0)
            spr(20,obstacle.x+8,obstacle.y,0)
            spr(21,obstacle.x+8,obstacle.y+8  ,0)
            if obstacle.l == 4 then
                spr(65,obstacle.x-6,obstacle.y+4,0)
            elseif obstacle.l == 3 then
                spr(66,obstacle.x-6,obstacle.y+4,0)
            elseif obstacle.l == 2 then
                spr(67,obstacle.x-6,obstacle.y+4,0)
            elseif obstacle.l == 1 then
                spr(68,obstacle.x-6,obstacle.y+4,0)
            end
        end
    end

    -- on vient récupérer la liste des projectile et on l'analyse du dernier vers le premier
    for n=#listP,1,-1 do
        -- on assigne les éléments récupérer sur la variable projectile
        local projectile=listP[n]
        -- et on vient donc générer le sprite du projectile
        if projectile.shooter == 0 then
            spr(3,projectile.x,projectile.y,0) 
        elseif projectile.shooter == 3 then
            spr(4,projectile.x,projectile.y,0)
            spr(5,projectile.x,projectile.y+8,0)
        end
    end

    for sP=#spell_list,1,-1 do
        local spell = spell_list[sP]
        local spell_draw_boolean = 0
        if spell.active and spell_duration <= 180 then
            if spell_draw_boolean <= 80 then
                spr(101,spell.x-8,spell.y,0)
                for screen_width=231,0,-8 do
                    spr(100,screen_width-8,spell.y,0)
                end
            elseif spell_draw_boolean <= 180 and spell_draw_boolean > 80 then
                spr(103,spell.x-8,spell.y,0)
                for screen_width=231,0,-8 do
                    spr(102,screen_width-8,spell.y,0)
                end
            end
        end
    end

    for pSpell=#spell_particle_list,1,-1 do
        local ptc=spell_particle_list[pSpell]
        spr(ptc.s,ptc.x,ptc.y,0)
    end

    for nPtc=#list_particule,1,-1 do
        local ptc=list_particule[nPtc]
        spr(ptc.s,ptc.x,ptc.y,0)
    end

    -- on imprime le score 
    --print(player_score.." ("..#listO..")",2,2,12)
    -- on imprime les chronos
    --print(chrono.." sec",50,2,12)

    print("power : "..player_power.." // vie : "..player_life.." // spell : "..player_spell.." // \n score : "..player_score.." // time : "..chrono, 2,2,12)

    --print("pdv"..player_life,2,30,12)

    --print("nombre de spell"..player_spell,2,100,12)

end

-- la fonction tic tourne 60x par seconde
function TIC()

    -- si nous n'avons pas arrêté le jeu alors
    if gamestop==false then
        -- on continue d'appeler update et draw
        update()
        draw()
    end

    -- si nous arrêtons le jeu, alors
    if gamestop then
        -- on clear la console
        cls(13)

        -- et on affiche le résultat en fonction des data en fin de partie, si négatif gameover, si positif win
        if player_dead then
            print("You are dead, your score is "..player_score,35,66)
        elseif player_score <= 0 then
            print("gameover",100,66)
        elseif player_score >= 0 then
            print("Yon SURVIVED, your score is "..player_score,35,66)
        end
    end

end
  