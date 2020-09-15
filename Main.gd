extends Spatial

enum {START_TOWER, WORK_TOWER, END_TOWER}

export var speed : = 1.0

class Movement:
	var from : int
	var to : int

const Disc = preload("res://Disc.tscn")

var disc_amount : = 5
var move_disc_ready : = true setget set_ready, get_ready
var floating_height : float
var y_offset : float
var disc_height : float
var x_distance :  float
var towers = []
var discs_start = []
var discs_work = []
var discs_end = []
var movement_queue = []

onready var start_tower = get_node("Towers/Start")
onready var work_tower = get_node("Towers/Work")
onready var end_tower = get_node("Towers/End")
onready var tween = get_node("Tween")

# primeiro codigo que roda ao carregar a cena
func _ready():
	# velocidade da operacao
	speed = $Control/HSlider.value
	# o programa recebe a quantidade de discos que o usuario especificou
	# e os postes e a base são redimensionados para acomodá-los
	disc_amount = Autoload.disc_count 
	set_env(disc_amount)
	
	# os vetores que representam cada torre são adicionados a um outro vetor
	towers = [discs_start, discs_work, discs_end]
	
	# as distancias fisicas necessarias para transportar os discos sao medidas
	floating_height = start_tower.mesh.height + 0.5
	x_distance = end_tower.translation.x
	
	# funcao que instancia os objetos dos discos
	_spawn_discs()
	
	# a sequencia de comandos para resolver a torre é gerada
	movement_queue = solve_hanoi(disc_amount, START_TOWER, END_TOWER, WORK_TOWER)
	
	# o primeiro movimento dá inicio ao processo
	var first = movement_queue.pop_back()
	request_movement(first)

# funcao que gera os discos
func _spawn_discs(): 
	# as posicoes dos discos subsequentes dependem das especificacoes do 
	# primeiro disco, entao ele é instanciado fora do loop
	var first_disc = Disc.instance()
	y_offset = first_disc.get_node("CSGCombiner/OuterCylinder").height/2
	disc_height = first_disc.get_node("CSGCombiner/OuterCylinder").height
	var base_radius = first_disc.get_node("CSGCombiner/OuterCylinder").radius
	var start_pos : = Vector3(start_tower.translation.x, 0 + y_offset ,start_tower.translation.z)
	first_disc.translation = start_pos
	add_child(first_disc)
	
	# os discos criados sao guardados no vetor que representa o primeiro poste
	discs_start.push_back(first_disc)
	
	# caso haja um numero grande de discos, o disco de baixo deve ser mais largo
	# que o padrão, pois todos os outros obtem suas dimensões decrementando
	# do raio do primeiro disco
	if disc_amount > 5:
		base_radius += (disc_amount - 5) * 0.2
		first_disc.get_node("CSGCombiner/OuterCylinder").radius = base_radius
		
	# loop que carrega o modelo 3d do disco, ajusta sua posiccao 
	# e o instancia na cena, além de adicioná-lo ao vetor do primeiro poste 
	for disc in range(disc_amount - 1):
		var disc_index = disc + 1
		var new_disc = Disc.instance()
		new_disc.get_node("CSGCombiner/OuterCylinder").radius = base_radius - disc_index * 0.2
		new_disc.translation = start_pos + Vector3(0,disc_height * disc_index,0)
		discs_start.push_back(new_disc)
		add_child(new_disc)
		
# funcao que move um disco entre um poste e outro
# Movement é uma classe que tem as propriedades 'from' e 'to'
# e descreve esse movimento
func _move_disc(movement : Movement) -> void: 
	# como para que um disco seja movido o movimento anterior deve
	# ter acabado, a propriedade ready indica quando outro movimento pode 
	# comecar
	set_ready(false)

	# o disco a ser movido é retirado do vetor do poste incial
	var disc = towers[movement.from].pop_back()
	
	# o movimento é feito em tres etapas retilineas.
	# Entre cada, existe uma chamada de "yield" que garente que
	# a funcao so continue quando a anterior terminar.
	# Alem disso sao calculadas as trajetorias de cada etapa com base 
	# na altura e distância dos postes e quantidade de discos em cada um
	var new_y_pos = Vector3(disc.translation.x, floating_height, disc.translation.z)
	tween.interpolate_property(disc, "translation", disc.translation, new_y_pos,  1/speed,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_completed")
	
	var x_movement = (movement.to - movement.from) * x_distance
	var new_x_pos =  Vector3(disc.translation.x + x_movement, disc.translation.y, disc.translation.z)
	tween.interpolate_property(disc, "translation", disc.translation, new_x_pos,  1/speed,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_completed")
	
	var final_height = 0 + y_offset + towers[movement.to].size() * disc_height
	new_y_pos = Vector3(disc.translation.x, final_height, disc.translation.z)
	tween.interpolate_property(disc, "translation", disc.translation, new_y_pos,  1/speed,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_completed")
	towers[movement.to].push_back(disc)

	#após o fim do movimento, a funcao pode ser executada de novo
	set_ready(true)

# funcao que pede para que um disco seja movido.
# Caso haja outro movimento em progresso, o disco entra
# em uma fila.
func request_movement(m : Movement):
	if get_ready():
		_move_disc(m)
	else:
		movement_queue.push_back(m) 
		
func get_ready():
	return move_disc_ready

# Essa funcao é chamada no fim de um movimento.
# Ela chama o movimento novamente, gerando um ciclo 
# que so termina quando a fila se esvazia
func set_ready(r  : bool):
	move_disc_ready = r
	if r:
		var curr_mov = movement_queue.pop_back()
		if curr_mov != null:
			_move_disc(curr_mov)

# Funcao que ajusta as dimencoes dos modelos 3d para acomodar 
# os discos
func set_env(c : int):
	if c > 5:
		$Base.mesh.size.x += (c - 5) * 0.2 * 10
		start_tower.translation.x -= (c - 5) * 0.2 * 2
		end_tower.translation.x += (c - 5) * 0.2 * 2
		$Camera.translation.z += (c - 5) * 0.2 
	pass

# Implementacão recursiva do algoritmo que resolve
# a Torre de Hanói, e retorna um vetor de objetos do
# tipo 'Movement', que descreve a fila de movimentos
func solve_hanoi(n : int, start_t, end_t, work_t):
	var moves = []
	var move = Movement.new()
	if n == 1: 
		move.from = start_t
		move.to = end_t
		moves.push_front(move)
		return moves
	moves = solve_hanoi(n-1, start_t, work_t, end_t) + moves
	move.from = start_t
	move.to = end_t
	moves.push_front(move)
	moves = solve_hanoi(n-1, work_t, end_t, start_t)  + moves
		
	return moves

# atualiza a velocidade dos discos
# quando o 'slider' é alterado
func _on_HSlider_value_changed(value):
	speed = $Control/HSlider.value


func _on_Info_pressed():
	get_tree().change_scene("res://Creditos.tscn")


func _on_Return_pressed():
	get_tree().change_scene("res://UI.tscn")


func _on_Exit_pressed():
	get_tree().quit()
