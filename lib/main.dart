import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_2048_flutter/model.dart';
import 'package:game_2048_flutter/utils.dart';

// https://www.bilibili.com/video/av70597509?from=search&seid=14378014657837074443
// https://www.youtube.com/watch?v=R_rZxtJBr9Q&t=775s

// flutter 嵌套过多，很容易忘记一些属性，所以编码时可以先把属性写上，即便没有确定值，占位以防止之后忘记
// 就像书写框架时先写好步骤然后填坑

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '2048 flutter',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(
          title: Text('2048 flutter'),
        ),
        body: BoardWidget(),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final _BoardWidgetState state;
  const MyHomePage({this.state});

  @override
  Widget build(BuildContext context) {
    Size boardSize = state.boardSize();
    double width = (boardSize.width - (state.column + 1) * state.tilePadding) /
        state.column;

    List<TileBox> backgroundBox = List<TileBox>();

    for (int r = 0; r < state.row; r++) {
      for (int c = 0; c < state.column; c++) {
        TileBox tile = TileBox(
          left: c * width * state.tilePadding * (c + 1),
          top: r * width * state.tilePadding * (r + 1),
          size: width,
        );
        backgroundBox.add(tile);
      }
    }

    return Positioned(
      left: 0.0,
      top: 0.0,
      child: Container(
        width: state.boardSize().width,
        height: state.boardSize().width,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: Stack(
          children: backgroundBox,
        ),
      ),
    );
  }
}

class BoardWidget extends StatefulWidget {
  @override
  _BoardWidgetState createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  Board _board;
  int row;
  int column;
  bool _isMoving;
  bool _isGameOver;
  double tilePadding = 5.0;
  MediaQueryData _queryData;

  @override
  void initState() {
    super.initState();

    row = 4;
    column = 4;
    _isMoving = false;
    _isGameOver = false;

    _board = Board(row, column);
    newGame();
  }

  void newGame() {
    setState(() {
      _board.initBoard();
      _isGameOver = false;
    });
  }

  void gameOver() {
    setState(() {
      if (_board.gameOver()) {
        _isGameOver = true;
      }
    });
  }

  Size boardSize() {
    Size size = _queryData.size;
    return Size(size.width, size.width);
  }

  @override
  Widget build(BuildContext context) {
    _queryData = MediaQuery.of(context);
    List<TileWidget> _tileWidgets = List<TileWidget>();
    for (int r = 0; r < row; r++) {
      for (int c = 0; c < column; c++) {
        _tileWidgets.add(TileWidget(tile: _board.getTile(r, c), state: this));
      }
    }

    List<Widget> children = List<Widget>();
    children.add(MyHomePage(
      state: this,
    ));
    children.addAll(_tileWidgets);
    return Column(
      children: <Widget>[
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Container(
                color: Colors.orange[100],
                width: 120.0,
                height: 60.0,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text("Score: "),
                      Text('${_board.score}'),
                    ],
                  ),
                ),
              ),
              FlatButton(
                child: Container(
                  width: 120.0,
                  height: 60.0,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      color: Colors.orange[100]),
                  child: Center(
                    child: Text('New Game'),
                  ),
                ),
                onPressed: () {
                  newGame();
                },
              ),
            ],
          ),
        ),
        Container(
          height: 40.0,
          child: Opacity(
            opacity: _isGameOver ? 1.0 : 0.0, //透明度
            child: Center(
              child: Text('Game Over'),
            ),
          ),
        ),
        Container(
          width: _queryData.size.width,
          height: _queryData.size.width,
          child: GestureDetector(
            onVerticalDragUpdate: (detail) {
              if (detail.delta.distance == 0 || _isMoving) {
                return;
              }
              _isMoving = true;
              if (detail.delta.direction > 0) {
                setState(() {
                  _board.moveDown();
                  gameOver();
                });
              } else {
                setState(() {
                  _board.moveUp();
                  gameOver();
                });
              }
            },
            onVerticalDragEnd: (d) {
              _isMoving = false;
            },
            onVerticalDragCancel: () {
              _isMoving = false;
            },
            onHorizontalDragUpdate: (detail) {
              if (detail.delta.distance == 0 || _isMoving) {
                return;
              }
              _isMoving = true;
              if (detail.delta.direction > 0) {
                setState(() {
                  _board.moveLeft();
                  gameOver();
                });
              } else {
                setState(() {
                  _board.moveRight();
                  gameOver();
                });
              }
            },
            onHorizontalDragEnd: (d) {
              _isMoving = false;
            },
            onHorizontalDragCancel: () {
              _isMoving = false;
            },
            child: Stack(
              children: children,
            ),
          ),
        )
      ],
    );
  }
}

class TileWidget extends StatefulWidget {
  final Tile tile;
  final _BoardWidgetState state;

  const TileWidget({Key key, this.tile, this.state}) : super(key: key);

  @override
  _TileWidgetState createState() => _TileWidgetState();
}

class _TileWidgetState extends State<TileWidget>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: Duration(
        milliseconds: 200,
      ),
      vsync: this,
    );

    animation = Tween(begin: 0.0, end: 1.0).animate(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
    widget.tile.isNew = false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tile.isNew && !widget.tile.isEmpty()) {
      controller.reset();
      controller.forward();
      widget.tile.isNew = false;
    } else {
      controller.animateTo(1.0);
    }

    return AnimatedTileWidget(
      tile: widget.tile,
      state: widget.state,
      animation: animation,
    );
  }
}

class AnimatedTileWidget extends AnimatedWidget {
  final Tile tile;
  final _BoardWidgetState state;

  AnimatedTileWidget(
      {Key key, this.tile, this.state, Animation<double> animation})
      : super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable;
    double animationValue = animation.value;
    Size boardSize = state.boardSize();
    double width = (boardSize.width - (state.column + 1) * state.tilePadding) /
        state.column;

    if (tile.value == 0) {
      return Container();
    } else {
      return TileBox(
        left: (tile.column * width +
            state.tilePadding * (tile.column + 1) +
            width / 2 * (1 - animationValue)),
        top: tile.row * width +
            state.tilePadding * (tile.row + 1) +
            width / 2 * (1 - animationValue),
        size: width * animationValue,
        color: tileColors.containsKey(tile.value)
            ? tileColors[tile.value]
            : Colors.orange[50],
        text: Text("${tile.value}"),
      );
    }
  }
}

class TileBox extends StatelessWidget {
  final double left;
  final double top;
  final double size;
  final Color color;
  final Text text;

  const TileBox(
      {Key key, this.left, this.top, this.size, this.color, this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
        ),
        child: Center(
          child: text,
        ),
      ),
    );
  }
}
