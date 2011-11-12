
#import "constants.h"
#import "datastructs.h"

@class GameModel;
@class GameScene;
@class Pack;
@class GameField;
@class Card;

@interface GameGrid: NSObject {
    GameModel * theModel;
	GameScene * theGame;
	NSMutableArray * gameField;
	int fieldIndexes[GRID_HEIGHT][GRID_WIDTH];
	int xScore[2][GRID_HEIGHT][GRID_WIDTH];
	Constraint xCheck[2][GRID_HEIGHT][GRID_WIDTH];
	bool hasBranch[2][GRID_HEIGHT][GRID_WIDTH];
}
@property (nonatomic,retain)NSMutableArray * gameField;

- (id) initWithGame:(GameScene*)Game andPack:(Pack*)pack;
- (void) draw;

- (GameField *) moveEndCardOfType:(int)Type inPos:(CGPoint)Pos;
- (void) pickUpCard:(Card*)card;
- (int) wordsCorrect;

- (BOOL) isAnchorAtX:(int)x andY:(int)y;
- (BOOL) hasCardAtX:(int)x andY:(int)y;
- (Card*) getCardAtX:(int)x andY:(int)y;

- (GameField*) fieldAtX:(int)x andY:(int)y;
- (void) removeField:(GameField*)field;

- (BOOL) hasCardXLetter:(char)letter atX:(int)x andY:(int)y andOri:(int)ori;
- (void) calcXValues;
@end
