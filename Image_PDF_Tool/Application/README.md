#### 端云一体化开发在线文档：
https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/agc-harmonyos-clouddev-overview

### 生产和测试双签名认证
采用了最新的release的版本的Dev Studio , 6.1.1 

#### 生产认证
参考
https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-publish-app#section793484619307
https://developer.huawei.com/consumer/cn/doc/app/agc-help-release-cert-0000002283336729

26.0.0 Beta1以下版本
1、先通过Build -> Generate key 输入信息获取对应的 .csr 文件
2、然后上传到 华为官网上架的那个获取对应的  发布证书 
3、通过发布证书获取对应的 发布 Profile 文件
4、然后再 File  ->  Project StruXXX 里面Singing Config 里面添加信息即可


####  如果只配置生产的签名，那么运行到真机的时候他会报错，运行到模拟器可以
Install Failed: error: failed to install bundle.
code:9568322
error: signature verification failed due to not trusted app source.
View detailed instructions.
#### 目前采用生产的方式 
生成一套测试的对应的 Debug_Cert.cer 和 Debug_proDebug.p7b 文件 ，
另外2个HarmonyOS和生产一样。
在signingConfigs 中弄了2套代码，可以注释的方式来实现
