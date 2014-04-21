

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

# LIGHTING
light = new THREE.AmbientLight(0xaaaaa)
scene.add(light)

light = new THREE.PointLight(0xffffff)
light.position.set(-25, 250, -78)
scene.add(light)

light = new THREE.PointLight(0x00ffff)
light.position.set(225, 250, -98)
scene.add(light)

light = new THREE.PointLight(0xff00ff)
light.position.set(255, -25, 97)
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
skyBoxMaterial = new THREE.MeshBasicMaterial(color: 0x000000, side: THREE.BackSide)
skyBox = new THREE.Mesh(skyBoxGeometry, skyBoxMaterial)
scene.add(skyBox)


###################################

materials = (new THREE.MeshLambertMaterial(color: 0xffffff) for i in [0..6])
faceMaterial = new THREE.MeshFaceMaterial(materials)

productGeometry = new THREE.CubeGeometry(180, 220, 50)
for face in productGeometry.faces
	face.color.setRGB(0, 0, 0.8 * Math.random() + 0.2)

product = new THREE.Mesh(productGeometry, faceMaterial)
product.position.set(0, 0, 0)
scene.add(product)

###################################

projector = new THREE.Projector()


$(renderer.domElement).on "mousemove", (e)-> 

	mouse.x = (e.clientX / window.innerWidth) * 2 - 1
	mouse.y = (e.clientY / window.innerHeight) * -2 + 1
	
	vector = new THREE.Vector3(mouse.x, mouse.y, 1)
	projector.unprojectVector(vector, camera)
	ray = new THREE.Raycaster(camera.position, vector.sub(camera.position).normalize())

	intersects = ray.intersectObjects([product])
	mouse.intersect = intersects[0]
	
	#if mouse.intersect
	#	mouse.intersect.face.color.setRGB(Math.random(), Math.random(), Math.random()) 
	#	mouse.intersect.object.geometry.colorsNeedUpdate = true

$("body").on "dragover dragenter drop", (e)-> 
	e.preventDefault()
	
	dt = e.originalEvent.dataTransfer
	intersect = mouse.intersect
	
	console.log e.type
	if intersect and dt?.files?.length
		console.log "dropped file on box"
		for file in dt.files
			if file.type.match /image/
				fr = new FileReader()
				fr.onload = ->
					mid = intersect.face.materialIndex
					materials[mid].map = THREE.ImageUtils.loadTexture(fr.result)
					materials[mid].needsUpdate = true
				fr.readAsDataURL(file)
				

do animate = ->
	requestAnimationFrame(animate)
	renderer.render(scene, camera)
	controls.update()
