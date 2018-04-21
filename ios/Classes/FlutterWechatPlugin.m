#import "FlutterWechatPlugin.h"

@implementation FlutterWechatPlugin {
    FlutterEventSink _eventSink;
}

- (instancetype)init
{
    self = [super init];
    return self;
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"flutter_wechat"
                                     binaryMessenger:[registrar messenger]];
    FlutterEventChannel* eventChannel =
    [FlutterEventChannel eventChannelWithName:@"SendAuthResp"
                              binaryMessenger:[registrar messenger]];
    FlutterWechatPlugin* instance = [[FlutterWechatPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    [eventChannel setStreamHandler:instance];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary *arguments = [call arguments];
    NSNumber* wxType = arguments[@"type"];
    int type=[wxType intValue];
    if ([@"registerWechat" isEqualToString:call.method]) {
        NSLog(@"registerWechat");
        [WXApi registerApp:arguments[@"wxId"]];
        result(nil);
    }
    else if([@"shareText" isEqualToString:call.method]) {
        NSString* text= arguments[@"text"];
        SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
        req.text = text;
        req.bText = YES;
        req.scene = type==0?WXSceneSession:WXSceneTimeline;
        [WXApi sendReq:req];
        result(nil);
    }else if([@"shareImage" isEqualToString:call.method]){
        NSString* imgUrl= arguments[@"imgUrl"];
        WXMediaMessage *mediaMsg = [WXMediaMessage message];
        WXImageObject *imgObj = [WXImageObject object];
        imgObj.imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imgUrl]];
        mediaMsg.mediaObject = imgObj;
        SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
        req.message = mediaMsg;
        req.bText = NO;
        req.scene = type==0?WXSceneSession:WXSceneTimeline;
        [WXApi sendReq:req];
        result(nil);
    }else if([@"shareWebPage" isEqualToString:call.method]){
        NSString* webpageUrl= arguments[@"webpageUrl"];
        NSString* imgUrl= arguments[@"imgUrl"];
        NSString* webTitle= arguments[@"title"];
        NSString* webDescription= arguments[@"description"];
        WXMediaMessage* message =[WXMediaMessage message];
        message.title = webTitle;
        message.description =webDescription;
        NSData* data=[NSData dataWithContentsOfURL:[NSURL URLWithString:imgUrl]];
        [message setThumbImage:[UIImage imageWithData:data]];
        WXWebpageObject* webpageObject = [WXWebpageObject object];
        webpageObject.webpageUrl =webpageUrl;
        message.mediaObject = webpageObject;
        SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
        req.message = message;
        req.bText = NO;
        req.scene = type==0?WXSceneSession:WXSceneTimeline;
        [WXApi sendReq:req];
        result(nil);
    }else if([@"shareMusic" isEqualToString:call.method]){
        NSString* musicUrl= arguments[@"musicUrl"];
        NSString* imgUrl= arguments[@"imgUrl"];
        NSString* musicTitle= arguments[@"title"];
        NSString* musicDescription= arguments[@"description"];
        NSString* musicDataUrl= arguments[@"musicDataUrl"];
        WXMediaMessage* message =[WXMediaMessage message];
        message.title = musicTitle;
        message.description =musicDescription;
        NSData* data=[NSData dataWithContentsOfURL:[NSURL URLWithString:imgUrl]];
        [message setThumbImage:[UIImage imageWithData:data]];
        WXMusicObject* musicObject = [WXMusicObject object];
        musicObject.musicUrl =musicUrl;
        musicObject.musicDataUrl = musicDataUrl;
        message.mediaObject = musicObject;
        SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
        req.message = message;
        req.bText = NO;
        req.scene = type==0?WXSceneSession:WXSceneTimeline;
        [WXApi sendReq:req];
        result(nil);
    }else if([@"shareVideo" isEqualToString:call.method]){
        NSString* videoUrl= arguments[@"videoUrl"];
        NSString* imgUrl= arguments[@"imgUrl"];
        NSString* videoTitle= arguments[@"title"];
        NSString* videoDescription= arguments[@"description"];
        WXMediaMessage* message =[WXMediaMessage message];
        message.title = videoTitle;
        message.description =videoDescription;
        NSData* data=[NSData dataWithContentsOfURL:[NSURL URLWithString:imgUrl]];
        [message setThumbImage:[UIImage imageWithData:data]];
        WXVideoObject* musicObject = [WXVideoObject object];
        musicObject.videoUrl =videoUrl;
        
        message.mediaObject = musicObject;
        SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
        req.message = message;
        req.bText = NO;
        req.scene = type==0?WXSceneSession:WXSceneTimeline;
        [WXApi sendReq:req];
        result(nil);
    }else if([@"login" isEqualToString:call.method]){
        NSString* scope= arguments[@"scope"];
        NSString* state= arguments[@"state"];
        SendAuthReq* req =[[SendAuthReq alloc] init];
        req.scope = scope;
        req.state = state;

        //第三方向微信终端发送一个SendAuthReq消息结构
        [WXApi sendReq:req];
        result(nil);
    }
}
-(BOOL)handleOpenURL:(NSNotification *)aNotification
{
    NSString * aURLString =  [aNotification userInfo][@"url"];
    NSURL * aURL = [NSURL URLWithString:aURLString];
    if ([WXApi handleOpenURL:aURL delegate:self])
    {
        return YES;
    } else {
        return NO;
    }
    
}

-(void) onResp:(BaseResp*)resp
{
    if([resp isKindOfClass:[SendMessageToWXResp class]])
    {
         _eventSink([NSString stringWithFormat:@"%d",resp.errCode]);
    } else if ([resp isKindOfClass:[SendAuthResp class]]) {
        SendAuthResp *r = (SendAuthResp *)resp;
        if (!_eventSink) return;
        if (r.errCode == WXSuccess)
        {
           _eventSink(resp.code);
        }else{
            _eventSink([NSString stringWithFormat:@"%d",r.errCode]);
        }
        if(resp.errCode==WXSuccess){
            
        }else{
            
        }
    } else if ([resp isKindOfClass:[PayResp class]]) {
        
    }
}
#pragma mark FlutterStreamHandler impl

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    _eventSink = eventSink;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleOpenURL:)
                                                 name:@"WeChat"
                                               object:nil];
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _eventSink = nil;
    return nil;
}


@end
