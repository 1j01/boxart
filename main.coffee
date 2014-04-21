

mouse = {x: 0, y: 0}


# SCENE
scene = new THREE.Scene()

# CAMERA
WIDTH = window.innerWidth
HEIGHT = window.innerHeight
ASPECT = WIDTH / HEIGHT
VIEW_ANGLE = 45
NEAR = 0.1
FAR = 20000
camera = new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR)
scene.add(camera)
camera.position.set(0, 150, 400)
camera.lookAt(scene.position)

# RENDERER
renderer = 
	if Detector.webgl
		new THREE.WebGLRenderer(antialias: yes)
	else
		new THREE.CanvasRenderer()

renderer.setSize(WIDTH, HEIGHT)
document.body.appendChild(renderer.domElement)


$(window).on "resize", ->
	WIDTH = window.innerWidth
	HEIGHT = window.innerHeight
	ASPECT = WIDTH / HEIGHT
	
	renderer.setSize(WIDTH, HEIGHT)
	camera.aspect = ASPECT
	camera.updateProjectionMatrix()


# CONTROLS
controls = new THREE.OrbitControls(camera, renderer.domElement)

# STATS
stats = new Stats()
stats.domElement.style.position = 'absolute'
stats.domElement.style.bottom = '0px'
stats.domElement.style.zIndex = 100
document.body.appendChild(stats.domElement)

# LIGHT
light = new THREE.PointLight(0xffffff)
light.position.set(0,250,0)
scene.add(light)

# FLOOR
###
floorTexture = new THREE.ImageUtils.loadTexture 'images/checkerboard.jpg'
floorTexture.wrapS = floorTexture.wrapT = THREE.RepeatWrapping 
floorTexture.repeat.set(10, 10)
floorMaterial = new THREE.MeshBasicMaterial(map: floorTexture, side: THREE.DoubleSide)
floorGeometry = new THREE.PlaneGeometry(1000, 1000, 10, 10)
floor = new THREE.Mesh(floorGeometry, floorMaterial)
floor.position.y = -0.5
floor.rotation.x = Math.PI / 2
scene.add(floor)
###

# SKYBOX/FOG
skyBoxGeometry = new THREE.CubeGeometry(10000, 10000, 10000)
skyBoxMaterial = new THREE.MeshBasicMaterial(color: 0x9999ff, side: THREE.BackSide)
skyBox = new THREE.Mesh(skyBoxGeometry, skyBoxMaterial)
scene.add(skyBox)


###################################

# this material causes a mesh to use colors assigned to faces
faceColorMaterial = new THREE.MeshBasicMaterial(color: 0xffffff, vertexColors: THREE.FaceColors)

productGeometry = new THREE.CubeGeometry(180, 220, 50)
for face in productGeometry.faces
	face.color.setRGB(0, 0, 0.8 * Math.random() + 0.2)

product = new THREE.Mesh(productGeometry, faceColorMaterial)
product.position.set(0, 0, 0)
scene.add(product)

###################################

projector = new THREE.Projector()


$(renderer.domElement).on "mousemove", (e)-> 

	# the following line would stop any other event handler from firing
	# (such as the mouse's TrackballControls)
	# e.preventDefault()
	
	# update the mouse variable
	mouse.x = (e.clientX / window.innerWidth) * 2 - 1
	mouse.y = (e.clientY / window.innerHeight) * -2 + 1
	
	# find intersections

	# create a Ray with origin at the mouse position
	#   and direction into the scene (camera direction)
	vector = new THREE.Vector3(mouse.x, mouse.y, 1)
	projector.unprojectVector(vector, camera)
	ray = new THREE.Raycaster(camera.position, vector.sub(camera.position).normalize())

	# create an array containing all objects in the scene with which the ray intersects
	intersects = ray.intersectObjects([product])
	
	# if there is one (or more) intersections
	if intersects.length > 0
		# change the color of the closest face.
		intersects[0].face.color.setRGB(Math.random(), Math.random(), Math.random()) 
		intersects[0].object.geometry.colorsNeedUpdate = true



animate = ->
	requestAnimationFrame(animate)
	renderer.render(scene, camera)
	update()

update = ->
	controls.update()
	stats.update()

animate()
