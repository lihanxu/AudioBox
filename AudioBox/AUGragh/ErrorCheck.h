//
//  ErrorCheck.h
//  TestFFmpeg
//
//  Created by anker on 2022/1/28.
//

#ifndef ErrorCheck_h
#define ErrorCheck_h

#define INPUT_BUS                   (1)
#define OUTPUT_BUS                  (0)

static void CheckStatus(OSStatus status, NSString *message, BOOL fatal)
{
    if(status != noErr)
    {
        char fourCC[16];
        *(UInt32 *)fourCC = CFSwapInt32HostToBig(status);
        fourCC[4] = '\0';
        
        if(isprint(fourCC[0]) && isprint(fourCC[1]) && isprint(fourCC[2]) && isprint(fourCC[3]))
            NSLog(@"%@: %s", message, fourCC);
        else
            NSLog(@"%@: %d", message, (int)status);
        
        if(fatal)
            exit(-1);
    }
}

#endif /* ErrorCheck_h */
