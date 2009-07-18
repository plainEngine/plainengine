#import <MPIrrlichtRenderSubject.h>
#import <MPUtility.h>
#import <cstdlib>

#import <MPMouse.h>

using namespace irr;

using namespace core;
using namespace scene;
using namespace video;
using namespace io;
using namespace gui;

E_DRIVER_TYPE getDriverTypeByName(NSString *aName)
{
	E_DRIVER_TYPE result = EDT_SOFTWARE;

	NSCAssert(aName, @"Driver name is nil!");

#define MP_DRIVER_TYPE_BY_NAME(name)\
	if ( [[aName uppercaseString] isEqual: @#name] )\
	{\
		result = EDT_##name;\
	}

	MP_DRIVER_TYPE_BY_NAME(SOFTWARE);
	MP_DRIVER_TYPE_BY_NAME(OPENGL);
	MP_DRIVER_TYPE_BY_NAME(DIRECT3D8);
	MP_DRIVER_TYPE_BY_NAME(DIRECT3D9);

#undef MP_DRIVER_TYPE_BY_NAME
	return result;
}

@implementation MPIrrlichtRenderSubject

- initWithString: (NSString *)aParams
{
	[super init];

	api = nil;
	log = nil;
	objSys = nil;

	device = NULL;
	driver = NULL;
	smgr = NULL;
	guienv = NULL;

	NSDictionary *defaults = nil, *resultConf = nil, *userConf = nil;

	defaults = [[NSDictionary alloc] initWithObjectsAndKeys: @"640", @"width", @"480", @"height", @"32", @"bpp", @"NO", @"fullscreen", @"YES", @"showCursor", @"plainEngine Irrlicht render.", @"caption", @"software", @"driver", nil];

	userConf = parseParamsString(aParams);
	resultConf = MPCreateConfigDictionary(defaults, userConf);

	winWidth = [[resultConf objectForKey: @"width"] intValue];
	winHeight = [[resultConf objectForKey: @"height"] intValue];
	winFullscreen = [[resultConf objectForKey: @"fullscreen"] boolValue];
	winBpp = [[resultConf objectForKey: @"bpp"] intValue];
	winShowCursor = [[resultConf objectForKey: @"showCursor"] boolValue];
	winCaption = [[resultConf objectForKey: @"caption"] copy];
	winDriverType = getDriverTypeByName([resultConf objectForKey: @"driver"]);

	[defaults release];

	return self;
}

- init
{
	return [self initWithString: @""];
}

- (void) dealloc
{
	[api release];
	[super dealloc];
}

- (void) receiveAPI: (id<MPAPI>)anAPI
{
	api = [anAPI retain];
	log = [api log];
	objSys = [api getObjectSystem];

}

- (void) start
{
	[log add: notice withFormat: @"Initializing Irrlicht..."];

	MPInitProfiling(&frame_stat);
	MPInitProfiling(&drawing_stat);

	device = createDevice(winDriverType, dimension2d<s32>(winWidth, winHeight), winBpp, winFullscreen, false, false, NULL);

	eventHandler = new MPIrrEventHandler(api, device);
	NSAssert(eventHandler != NULL, @"eventHandler doesn't initialized!");
	device->setEventReceiver(eventHandler);

	// start setting window caption
	unsigned len = [winCaption length]*4;
	char *buf = new char[len];

	strncpy(buf, [winCaption UTF8String], len);
	wchar_t *capt = new wchar_t[len];
	mbstowcs(capt, (char *)buf, len);
	capt[len-1] = 0;

	device->setWindowCaption(capt);

	delete[] capt;
	delete[] buf;
	// end %)
	
	driver = device->getVideoDriver();
	smgr = device->getSceneManager();
	guienv = device->getGUIEnvironment();
	
	[self showCursor: winShowCursor];
	device->setResizeAble(false);
	driver->setTextureCreationFlag(ETCF_ALWAYS_32_BIT, true);
	driver->setTextureCreationFlag(ETCF_CREATE_MIP_MAPS, true);

	ICameraSceneNode* cam = smgr->addCameraSceneNode(0, 
				vector3df(0, 0, -10), // position
				vector3df(0, 0, 0) //target
				);
	float aRatio = cam->getAspectRatio();
	float scale = 1.0f;
	cam->setProjectionMatrix(matrix4().buildProjectionMatrixOrthoLH(
				2.0*aRatio*scale, 2.0*scale, cam->getNearValue(), cam->getFarValue()
				), true);
	smgr->addToDeletionQueue(cam);

	IBillboardSceneNode* node = smgr->addBillboardSceneNode(0);
	if (node)
	{
		node->setPosition(core::vector3df(0,0,0));
		node->setSize(dimension2d<f32>(2, 2));
		node->setMaterialFlag(video::EMF_LIGHTING, false);
		ITexture *tex1 = NULL;
		tex1 = driver->getTexture("./bubble.png");
		node->setMaterialTexture(0, tex1);
		node->setMaterialType(EMT_TRANSPARENT_ALPHA_CHANNEL);
	}

	[[api getObjectSystem] registerDelegate: [MPMouse class] forFeature: @"mouse"];

	[log add: notice withFormat: @"MPIrrlichtRenderSubject: initialization done"];
}

- (void) stop
{
	[[api getObjectSystem] removeDelegate: [MPMouse class] forFeature: @"mouse"];
	
	device->setEventReceiver(NULL);
	delete eventHandler;

	device->drop();
	[log add: notice withFormat: @"MPIrrlichtRenderSubject: device dropped"];

	[log add: notice withFormat: @"Drawing statistics:\n %@\n", MPPrintProfilingStatistics(&drawing_stat)];
	[log add: notice withFormat: @"Whole frame statistics:\n %@\n", MPPrintProfilingStatistics(&frame_stat)];
}

- (void) update
{
	MPBeginProfilingSession(&frame_stat);
	if (device->run())
	{
		MPBeginProfilingSession(&drawing_stat);
		driver->beginScene(true, true, SColor(255,100,101,140));

		smgr->drawAll();
		guienv->drawAll();

		driver->endScene();
		MPEndProfilingSession(&drawing_stat);
	}
	else
	{
		[api postMessageWithName: @"exit"];
	}
	MPEndProfilingSession(&frame_stat);
}

MP_HANDLER_OF_MESSAGE(showCursor)
{
	[self showCursor: [[MP_MESSAGE_DATA objectForKey: @"state"] boolValue]];
}

- (BOOL) isFullscreen
{
	return winFullscreen;
}

- (BOOL) isCursorVisible
{
	return winShowCursor;
}
- (void) showCursor: (BOOL)show
{
	// update internal flag
	winShowCursor = show;
	// update irrlicht device state
	device->getCursorControl()->setVisible(winShowCursor); 
}

- (NSSize) getWindowSize
{
	NSSize size;
	size.width = winWidth;
	size.height = winHeight;

	return size;
}
@end
