//
//  ViewController.m
//  NSOperation
//
//  Created by 李根 on 16/7/7.
//  Copyright © 2016年 ligen. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property(nonatomic, strong)UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    
    
//    NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(run) object:nil];
//    //  注意: 默认情况下, 调用了start方法后并不会开一条新的线程去执行, 而是在当前线程同步执行操作, 只有将NSOperation放到一个NSOperationQueue中, 才会异步执行操作
//    [op start];
    
//    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
//        //  在主线程
//        NSLog(@"下载1------%@", [NSThread currentThread]);
//    }];
//    //  添加额外的任务(在子线程执行), 封装数大于1才会异步执行
//    [op addExecutionBlock:^{
//        NSLog(@"load2-----%@", [NSThread currentThread]);
//    }];
//    [op start];
    
    //  自定义Operation: 需要实现- (void)main方法, 需要做的事情放在main方法中
    
    //  NSOperationQueue来创建队列: 主队列和全局队列
    
    //  创建一个其他队列(包括串行队列和并发队列), 放到这个队列中的NSOperation对象会自动放到子线程中执行
//    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
//    
//    //  创建一个主队列, 放到这个队列中的NSOperation对象会自动放到子线程中执行
//    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
//    
//    //  表示并发数量: 即同时执行任务的最大数
//    queue.maxConcurrentOperationCount = 1;
    //  队列的取消, 暂停, 恢复:
    //  NSOperation的 - cancel方法也可以停止单个操作
    //  - (void)cancelALlOperations;
    //  YES代表暂停队列, NO代表恢复队列
    //  - (void)setSuspended:(BOOL)b;
    
    //  添加依赖
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSBlockOperation *block1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"download1--------%@", [NSThread currentThread]);
    }];
    NSBlockOperation *block2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"download2---------%@", [NSThread currentThread]);
    }];
    NSBlockOperation *block3 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"download3--------%@", [NSThread currentThread]);
    }];
    //  添加依赖: block1和block2执行完后, 再执行block3, block3依赖于block1和block2
    //  给block3添加依赖, 让block3在block1和block2之后执行
    [block3 addDependency:block1];
    [block3 addDependency:block2];
    
    [queue addOperation:block1];
    [queue addOperation:block2];
    [queue addOperation:block3];
    //  注意: 不能循环依赖, 但是可以跨队列依赖, 不管NSOperation对象在哪个队列. 只要是两个NSOperation对象就可以依赖线程间通信
    //  egs: 下载图片
    
#pragma mark    - 下载图片, operation实现线程间通信
    
//    [[[NSOperationQueue alloc] init] addOperation:[NSBlockOperation blockOperationWithBlock:^{
//        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://7xjanq.com1.z0.glb.clouddn.com/6478.jpg"]]];
//        
//        //  返回主线程
//        [[NSOperationQueue mainQueue] addOperation:[NSBlockOperation blockOperationWithBlock:^{
//            self.imageView.image = image;
//        }]];
//        
//    }]];
    
    //  egs: 下载图片1和图片2并合成图片
    [self combineNetworkImage];
    
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
        [self.view addSubview:_imageView];
        _imageView.center = self.view.center;
        
    }
    return _imageView;
}

- (void)combineNetworkImage {
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    __block UIImage *image1;
    NSBlockOperation *block1 = [NSBlockOperation blockOperationWithBlock:^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://img1.gtimg.com/15/1513/151394/15139471_980x1200_0.jpg"]];
        image1 = [UIImage imageWithData:data];
        NSLog(@"load image1: %@", [NSThread currentThread]);
    }];
    
    __block UIImage *image2;
    NSBlockOperation *block2 = [NSBlockOperation blockOperationWithBlock:^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://img1.gtimg.com/15/1513/151311/15131165_980x1200_0.png"]];
        image2 = [UIImage imageWithData:data];
        NSLog(@"load image2: %@", [NSThread currentThread]);
    }];
    
    NSBlockOperation *block3 = [NSBlockOperation blockOperationWithBlock:^{
        CGFloat imageW = self.imageView.bounds.size.width;
        CGFloat imageH = self.imageView.bounds.size.height;
        
        //  开启位图上下文
        UIGraphicsBeginImageContext(self.imageView.bounds.size);
        
        //  画图
        [image1 drawInRect:CGRectMake(0, 0, imageW * 0.5, imageH)];
        [image2 drawInRect:CGRectMake(imageW * 0.5, 0, imageW * 0.5, imageH)];
        
        //  将图片取出
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        
        //  关闭图形上下文
        UIGraphicsEndImageContext();
        
        //  在主线程显示图片
        [[NSOperationQueue mainQueue] addOperation:[NSBlockOperation blockOperationWithBlock:^{
            NSLog(@"combine image: %@", [NSThread currentThread]);
            self.imageView.image = image;
        }]];
        
    }];
    [block3 addDependency:block1];
    [block3 addDependency:block2];
    
    [queue addOperation:block1];
    [queue addOperation:block2];
    [queue addOperation:block3];
    
    
    //  线程同步: 为了防止多个线程抢夺同一个资源造成的数据安全问题, 所采用的一种措施
    //  互斥锁: 给需要同步的代码块加一个互斥锁, 就可以保证每次只有一个线程访问此代码块
//    @synchronized (self) {
//        <#需要执行的代码块#>
//    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
