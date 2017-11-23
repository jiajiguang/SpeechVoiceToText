//
//  ViewController.m
//  VoiceToText
//
//  Created by yang on 2017/11/21.
//  Copyright © 2017年 wondertek. All rights reserved.
//

#import "ViewController.h"
#import <Speech/Speech.h>
@interface ViewController ()<SFSpeechRecognizerDelegate>
//语音识别功能
@property(nonatomic,strong)SFSpeechAudioBufferRecognitionRequest * recognitionRequest ;
@property(nonatomic,strong)SFSpeechRecognitionTask * recognitionTask ;
@property(nonatomic,strong)AVAudioEngine * audioEngine ;
@property(nonatomic,strong)SFSpeechRecognizer * recognizer;
@end

@implementation ViewController{
    UIButton *recordingBtn;
    UITextField *textF;

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[UIScreen mainScreen] brightness];
    recordingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    recordingBtn.frame = CGRectMake(10, 300, self.view.frame.size.width-20, 50);
    [self.view addSubview:recordingBtn];
    recordingBtn.backgroundColor = [UIColor grayColor];
    [recordingBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    [recordingBtn setTitle:@"开始录制" forState:UIControlStateNormal];
    
    textF = [[UITextField alloc] initWithFrame:CGRectMake(10, 100, self.view.frame.size.width-20, 50)];
    [self.view addSubview:textF];
    textF.backgroundColor = [UIColor greenColor];
    
    NSLocale *cale = [[NSLocale alloc]initWithLocaleIdentifier:@"zh-CN"];
    self.recognizer = [[SFSpeechRecognizer alloc]initWithLocale:cale];
    recordingBtn.enabled = false;
    NSLog(@"可以设置语言种类：%@",[SFSpeechRecognizer supportedLocales]);
    //设置代理
    self.recognizer.delegate = self;
    
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        bool isButtonEnabled = false;
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                isButtonEnabled = true;
                NSLog(@"可以语音识别");
                break;
            case SFSpeechRecognizerAuthorizationStatusDenied:
                isButtonEnabled = false;
                NSLog(@"用户被拒绝访问语音识别");
                break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:
                isButtonEnabled = false;
                NSLog(@"不能在该设备上进行语音识别");
                break;
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                isButtonEnabled = false;
                NSLog(@"没有授权语音识别");
                break;
            default:
                break;
        }
        recordingBtn.enabled = isButtonEnabled;
    }];
    
    self.audioEngine = [[AVAudioEngine alloc]init];
}

- (void)btnClick:(UIButton *)sender{
    if ([self.audioEngine isRunning]) {
        [self.audioEngine stop];
        [self.recognitionRequest endAudio];
        sender.enabled = YES;
        [sender setTitle:@"开始录制" forState:UIControlStateNormal];
    }else{
        [self startRecording];
        [sender setTitle:@"停止录制" forState:UIControlStateNormal];
    }
    
}

- (void)startRecording{
    if (self.recognitionTask) {
        [self.recognitionTask cancel];
        self.recognitionTask = nil;
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    bool  audioBool = [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    bool  audioBool1= [audioSession setMode:AVAudioSessionModeMeasurement error:nil];
    bool  audioBool2= [audioSession setActive:true withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    if (audioBool || audioBool1||  audioBool2) {
        NSLog(@"可以使用");
    }else{
        NSLog(@"这里说明有的功能不支持");
    }
    //识别请求
    self.recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc]init];
    AVAudioInputNode *inputNode = self.audioEngine.inputNode;
    
    self.recognitionRequest.shouldReportPartialResults = true;
    
    //开始识别任务
    self.recognitionTask = [self.recognizer recognitionTaskWithRequest:self.recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        bool isFinal = false;
        if (result) {
            textF.text = [[result bestTranscription] formattedString]; //语音转文本
            isFinal = [result isFinal];
            if([textF.text isEqualToString:@"打开设置"]){
                //跳转到设置开启推送：
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([[UIApplication sharedApplication] canOpenURL:url])
                {
                    [[UIApplication sharedApplication] openURL:url];
                }
                textF.text = @"已打开";
                [self.audioEngine stop];
                [self.recognitionRequest endAudio];
                recordingBtn.enabled = YES;
                [recordingBtn setTitle:@"开始录制" forState:UIControlStateNormal];
            }else if([textF.text isEqualToString:@"打开微信"]){
                // 跳到微信
                NSString *str =@"weixin://";
                [[UIApplication sharedApplication] openURL:[[NSURL alloc] initWithString:str]];
                textF.text = @"已打开";
                [self.audioEngine stop];
                [self.recognitionRequest endAudio];
                recordingBtn.enabled = YES;
                [recordingBtn setTitle:@"开始录制" forState:UIControlStateNormal];
            }
        }
        if (error || isFinal) {
            [self.audioEngine stop];
            [inputNode removeTapOnBus:0];
            self.recognitionRequest = nil;
            self.recognitionTask = nil;
            recordingBtn.enabled = true;
        }
    }];
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [self.recognitionRequest appendAudioPCMBuffer:buffer];
    }];
    [self.audioEngine prepare];
    bool audioEngineBool = [self.audioEngine startAndReturnError:nil];
    NSLog(@"%d",audioEngineBool);
    textF.text = @"想聊会吗";
    
}

- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available{
    if (available) {
        recordingBtn.enabled = YES;
    }else{
        recordingBtn.enabled = NO;
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    [textF resignFirstResponder];//1方式
    [self.view endEditing:NO];//2方式
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
