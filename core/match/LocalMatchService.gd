class_name LocalMatchService
extends RefCounted
## MVP matchmaking: you plus bots. A NetworkMatchService can replace this later.

const PLAYER_SCENE := preload("res://characters/Player.tscn")


static func build_roster(lobby_size: int, rng: RandomNumberGenerator, human_name: String = "You") -> Array[Player]:
    var roster: Array[Player] = []

    var human: Player = PLAYER_SCENE.instantiate()
    human.player_id = 0
    human.display_name = human_name
    human.input = HumanInput.new()
    human.set_skin_color(Color("ac9ef3"))
    roster.append(human)

    var bot_names := BotRoster.pick_names(maxi(lobby_size - 1, 0), rng)
    for i in bot_names.size():
        var bot: Player = PLAYER_SCENE.instantiate()
        bot.player_id = i + 1
        bot.display_name = bot_names[i]
        bot.is_bot = true
        bot.set_skin_color(Color.from_hsv(float(i) / maxf(bot_names.size(), 1.0), 0.55, 0.9))
        var brain := BotBase.new()
        brain.skill = BotRoster.random_skill(rng)
        brain.bot_player = bot
        var bot_input := BotInput.new()
        bot_input.brain = brain
        bot.input = bot_input
        roster.append(bot)
    return roster
