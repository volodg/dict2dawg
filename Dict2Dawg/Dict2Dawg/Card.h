
@class CCSprite;
@class CCLabelTTF;

typedef int ccTime;

enum {
	eCardType_normal = 0,
	eCardType_pitDaemon,
	eCardType_deepFreeze,
	eCardType_giftOfNature,
	eCardType_airJihn,
	eCardType_phoenix
};

enum {
	eCardState_none = 0,
	eCardState_hand,
	eCardState_gamefield_free,
	eCardState_gamefield_fixed
};

@class GameScene;

@interface Card : NSObject {
	GameScene * theLayer;
	CCSprite * sprite;
//	CCLabelBMFont * label;
	CCLabelTTF * label;
	CCLabelTTF * labelCost;
	int type;
	int color;
	char letter;
	int state;
	int cost;
	int panelPlace;
}

@property (nonatomic) int type;
@property (nonatomic) int color;
@property (nonatomic) int state;
@property (nonatomic) int cost;
@property (nonatomic) int panelPlace;
@property (nonatomic) char letter;
@property (nonatomic,retain) CCSprite * sprite;

-(id) initWithType:(int)Type andColor:(int)Color andLetter:(char)Letter;
-(void) drawOnLayer:(GameScene *)layer atPosition:(CGPoint)Pos;
-(void) clear;
-(void) setZorder:(int)z;
-(bool) touchIn:(CGPoint)Pos;
-(void) moveBy:(CGPoint)Offset;
-(void) moveTo:(CGPoint)Pos;
-(void) moveTo:(CGPoint)Pos withDuration:(ccTime)time;
-(void) makeFixed;
-(void) select;
-(void) redrawAtPos:(CGPoint)pos;
-(CGPoint) position;

@end
