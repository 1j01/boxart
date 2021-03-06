
T = THREE

# SCENE
scene = new T.Scene()

# CAMERA
WIDTH = window.innerWidth
HEIGHT = window.innerHeight
ASPECT = WIDTH / HEIGHT
VIEW_ANGLE = 45
NEAR = 0.1
FAR = 20000
camera = new T.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR)
scene.add(camera)
camera.position.set(0, 150, 400)
camera.lookAt(scene.position)

# RENDERER
renderer = 
	if Detector.webgl
		new T.WebGLRenderer(antialias: yes)
	else
		new T.CanvasRenderer()

renderer.setSize(WIDTH, HEIGHT)
document.body.appendChild(renderer.domElement)

$(window).on 'resize', ->
	WIDTH = window.innerWidth
	HEIGHT = window.innerHeight
	ASPECT = WIDTH / HEIGHT
	
	renderer.setSize(WIDTH, HEIGHT)
	camera.aspect = ASPECT
	camera.updateProjectionMatrix()


# CONTROLS
controls = new T.OrbitControls(camera, renderer.domElement)

# LIGHTING
light = new T.AmbientLight(0xffffff)
scene.add(light)

# SKYBOX/FOG
skyBoxGeometry = new T.BoxGeometry(10000, 10000, 10000)
skyBoxMaterial = new T.MeshBasicMaterial(color: 0x000000, side: T.BackSide)
skyBox = new T.Mesh(skyBoxGeometry, skyBoxMaterial)
scene.add(skyBox)


###################################
# Product
###################################

canvases = for i in [0..6]
	canvas = document.createElement('canvas')
	canvas.width = canvas.height = 1024
	ctx = canvas.getContext('2d')
	ctx.fillStyle = '#ddd'
	ctx.fillRect(0, 0, canvas.width, canvas.height)
	
	ctx.lineWidth = 5
	ctx.strokeStyle = '#000'
	ctx.strokeRect(0, 0, canvas.width, canvas.height)
	
	canvas

materials = 
	for canvas in canvases
		map = new T.Texture(canvas)
		map.needsUpdate = true
		new T.MeshLambertMaterial
			side: T.FrontSide
			map: map

faceMaterial = new T.MeshFaceMaterial(materials)

productGeometry = product = null

###################################
# Mirror
###################################

planeGeom = new THREE.PlaneGeometry(10000.1, 10000.1)

groundMirror = new THREE.Mirror(
	renderer, camera
	{
		clipBias: 0.003
		textureWidth: WIDTH
		textureHeight: HEIGHT
		color: 0x101010
	}
)

mirrorMesh = new THREE.Mesh(planeGeom, groundMirror.material)
mirrorMesh.add(groundMirror)
mirrorMesh.rotateX(-Math.PI / 2)
mirrorMesh.position.set(0, -114, 0)
scene.add(mirrorMesh)

###################################

unprojector = new T.Projector()
mouse = {x: 0, y: 0}

$('body').on 'mousemove dragover dragenter drop', (e)-> 
	e.preventDefault()
	
	mouse.x = (e.originalEvent.offsetX / WIDTH) * 2 - 1
	mouse.y = (e.originalEvent.offsetY / HEIGHT) * -2 + 1
	
	vector = new T.Vector3(mouse.x, mouse.y, 1)
	unprojector.unprojectVector(vector, camera)
	ray = new T.Raycaster(camera.position, vector.sub(camera.position).normalize())
	
	intersects = ray.intersectObjects([product])
	
	if mouse.intersect
		mid = mouse.intersect.face.materialIndex
		materials[mid].emissive.setHex(0x000000)
		materials[mid].needsUpdate = true
	
	mouse.intersect = intersect = intersects[0]
	
	if mouse.intersect and e.type isnt 'mousemove'
		mid = intersect.face.materialIndex
		materials[mid].emissive.setHex(0xa0a0a0)
		materials[mid].needsUpdate = true
		
		dt = e.originalEvent.dataTransfer
		if e.type is 'drop' and dt?.files?.length
			for file in dt.files
				if file.type.match /image/
					fr = new FileReader()
					fr.onload = ->
						materials[mid].map = T.ImageUtils.loadTexture(fr.result)
						materials[mid].needsUpdate = true
						intersect.object.geometry.needsUpdate = true
					fr.readAsDataURL(file)


dimensions =
	# cuboid
	x: 1
	y: 1
	z: 1
	# cylinder
	r: 1
	h: 1

shape = "box" or "cylinder"

update_size = ->
	s = 10
	
	switch shape
		when "box"
			product.scale.x = dimensions.x * s
			product.scale.y = dimensions.y * s
			product.scale.z = dimensions.z * s
			
			mirrorMesh.position.set(0, - (dimensions.y * s / 2 + 4.23), 0)
		
		when "cylinder"
			product.scale.x = dimensions.r * s
			product.scale.y = dimensions.h * s
			product.scale.z = dimensions.r * s
			
			mirrorMesh.position.set(0, - (dimensions.h * s / 2 + 4.23), 0)

$('input').each (i)->
	d = 'xyzrh'[i]
	$(@).on('change', ->
		dimensions[d] = $(@).val()
		update_size()
	)

$('select#template').on 'change', ->
	shape = $(@).val()
	
	switch shape
		when "box"
			productGeometry = new T.BoxGeometry(1, 1, 1, 10, 10, 10)
			$('#cuboid-dimensions').show()
			$('#cylindrical-dimensions').hide()
		
		when "cylinder"
			productGeometry = new T.CylinderGeometry(1, 1, 1, 25, 25, no)
			$('#cuboid-dimensions').hide()
			$('#cylindrical-dimensions').show()
	
	scene.remove(product) if product
	product = new T.Mesh(productGeometry, faceMaterial)
	scene.add(product)
	update_size()

do animate = ->
	requestAnimationFrame(animate)
	groundMirror.render()
	renderer.render(scene, camera)
	controls.update()

$('select').trigger('change')
$('input').trigger('change')
