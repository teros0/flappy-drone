extends Resource
class_name SquashRules

enum Mode { VERSUS, SINGLEPLAYER }

@export var mode: Mode = Mode.SINGLEPLAYER
@export var winning_score: int = 7
@export var points_per_wall_hit: int = 1
@export var points_lost_on_bottom_miss: int = 1
@export var bottom_passes_before_miss: int = 2
