extends Node
class_name QuadTree

const MAX_DEPTH = 5		#最大深度


var boundary: Rect2  	#四叉树管理的区间
var capacity: int		#当前节点的存储容量
var objs: Array[QuadTreeObj]			#当前点的存储对象
var depth: int			#当前节点的深度
var divided: bool		#是否分割，未分割是叶子节点
var northeast: QuadTree	#东北节点
var northwest: QuadTree	#西北节点
var southeast: QuadTree	#东南节点
var southwest: QuadTree	#西南节点


#构造函数
func _init(_boundary: Rect2, _capacity: int, _depth: int = 1):
	boundary = _boundary
	capacity = _capacity
	objs = []
	divided = false
	depth = _depth

#分割方法
func _subdivide():
	var x = boundary.position.x
	var y = boundary.position.y
	var w = boundary.size.x / 2
	var h = boundary.size.y / 2
	var sub_depth = depth + 1

	var ne = Rect2(Vector2(x + w, y), Vector2(w, h))
	northeast = QuadTree.new(ne, capacity, sub_depth)

	var nw = Rect2(Vector2(x, y), Vector2(w, h))
	northwest = QuadTree.new(nw, capacity, sub_depth)

	var se = Rect2(Vector2(x + w, y + h), Vector2(w, h))
	southeast = QuadTree.new(se, capacity, sub_depth)

	var sw = Rect2(Vector2(x, y + h), Vector2(w, h))
	southwest = QuadTree.new(sw, capacity, sub_depth)

	divided = true

#插入对象
func insert(obj: QuadTreeObj) -> bool:
	if not boundary.has_point(obj.position):
		return false

	if objs.size() < capacity or depth == MAX_DEPTH:
		objs.append(obj)
		return true
	else:
		if not divided:
			_subdivide()
		if northeast.insert(obj):
			return true
		elif northwest.insert(obj):
			return true
		elif southeast.insert(obj):
			return true
		elif southwest.insert(obj):
			return true

	return false

#移除对象	
func remove(obj):
	if obj in objs:
		objs.erase(obj)
		merge()
		return true
	if divided:
		if northeast.remove(obj):
			return true
		if northwest.remove(obj):
			return true
		if southeast.remove(obj):
			return true
		if southwest.remove(obj):
			return true
	return false
	
#查询范围的对象
func query(range: Rect2, found_objs: Array):
	if not boundary.intersects(range):
		return

	for obj in objs:
		if range.has_point(obj.position):
			found_objs.append(obj)

	if divided:
		northeast.query(range, found_objs)
		northwest.query(range, found_objs)
		southeast.query(range, found_objs)
		southwest.query(range, found_objs)

#合并子节点
func merge():
	if not divided:
		return
	
	# 检查所有子节点是否都是叶子节点
	if northeast.divided or northwest.divided or southeast.divided or southwest.divided:
		return
		
	if northeast.objs.size() + northwest.objs.size() + southeast.objs.size() + southwest.objs.size() + objs.size() > capacity:
		return
	
	# 合并子节点中的点到当前节点
	objs += northeast.objs
	objs += northwest.objs
	objs += southeast.objs
	objs += southwest.objs
	
	# 清除子节点
	northeast = null
	northwest = null
	southeast = null
	southwest = null
	divided = false
