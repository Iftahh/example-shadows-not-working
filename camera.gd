extends Spatial

onready var camera = $Camera

const SCROLL_SPEED = 50
var UP:bool = false
var DOWN:bool = false
var LEFT:bool = false
var RIGHT:bool = false
var ZOOM_IN:bool = false
var ZOOM_OUT:bool = false



func _input(event):
	if event is InputEventMouseMotion:
		#rotations
		if event.button_mask&(BUTTON_MASK_MIDDLE+BUTTON_MASK_RIGHT):
			self.rotate(Vector3(0, 1,0), event.relative.x * -0.002)
			$Camera.rotate(Vector3(1,0,0), event.relative.y * -0.002)
	
	#zoom
	if event is InputEventMouseButton:
		ZOOM_IN = false
		ZOOM_OUT = false
		if event.is_pressed():
			# zoom in
			if event.button_index == BUTTON_WHEEL_DOWN:
				ZOOM_IN = true
				
			# zoom out
			if event.button_index == BUTTON_WHEEL_UP:
				ZOOM_OUT = true
	
	if Input.is_key_pressed(KEY_SPACE):
		print("Translation:  ", translation)
		print("Rotation: ", rotation)

			
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	if Input.is_key_pressed(KEY_R) or ZOOM_IN:
		#zoom
		self.translate(Vector3(0,SCROLL_SPEED*delta, 0))

	if Input.is_key_pressed(KEY_F) or ZOOM_OUT:
		self.translate(Vector3(0,-SCROLL_SPEED*delta, 0))
	
	# higher up the camera moves faster
	var scroll_speed = SCROLL_SPEED * translation.y / 50.0
	
	#scroll (with keyboard)
	if Input.is_key_pressed(KEY_W) or UP:
		self.translate(Vector3(0,0,-scroll_speed*delta))
		
	if Input.is_key_pressed(KEY_S) or DOWN:
		self.translate(Vector3(0,0,scroll_speed*delta))
		
	if (Input.is_key_pressed(KEY_A) or LEFT):	
		self.translate(Vector3(-scroll_speed*delta,0,0))
	if (Input.is_key_pressed(KEY_D) or RIGHT):
		self.translate(Vector3(scroll_speed*delta,0,0))
	#rotation (with keyboard)
	if Input.is_key_pressed(KEY_Q):
		self.rotate(Vector3(0, 1,0),1*delta)
	if Input.is_key_pressed(KEY_E):
		self.rotate(Vector3(0, 1,0),-1*delta)
	
