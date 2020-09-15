extends Node

def solve(
	disks=TOTAL_DISK_COUNT,
	_from=towers[START_TOWER],
	_to=towers[END_TOWER],
	_using=towers[WORK_TOWER]
	):
	if disks:
		solve(disks=disks-1, _from=_from, _to=_using, _using=_to)

		move = Movement(0,0)
		for tower in towers:
			if _from is towers[tower]:
				move._from = tower
			elif _to is towers[tower]:
				move._to = tower

		moves.append(move) # movement_queue.push_back(objeto)
		_to.append(_from.pop())
		print(towers)

		solve(disks=disks-1, _from=_using, _to=_to, _using=_from)

print("PROBLEM:", towers)
print("SOLUTION:")
solve()

print(moves)
