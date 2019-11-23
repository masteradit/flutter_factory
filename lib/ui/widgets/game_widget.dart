import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_factory/game/factory_equipment.dart';
import 'package:flutter_factory/game/model/coordinates.dart';
import 'package:flutter_factory/game/model/factory_equipment_model.dart';
import 'package:flutter_factory/game/model/factory_material_model.dart';
import 'package:flutter_factory/game_bloc.dart';
import 'package:flutter_factory/ui/theme/dynamic_theme.dart';
import 'package:flutter_factory/ui/theme/game_theme.dart';
import 'package:flutter_factory/ui/theme/themes/light_game_theme.dart';
import 'package:flutter_factory/ui/theme/theme_provider.dart';
import 'package:flutter_factory/ui/widgets/game_provider.dart';
import 'package:random_color/random_color.dart';

class GameWidget extends StatefulWidget {
  GameWidget({Key key}) : super(key: key);

  @override
  _GameWidgetState createState() => _GameWidgetState();
}

class _GameWidgetState extends State<GameWidget> {
  final List<Coordinates> _selected = <Coordinates>[];

  int doubleTapDuration = 300;
  int _lastTap = 0;
  Coordinates _lastTapLocation;

  List<FactoryEquipmentModel> _movingEquipment = <FactoryEquipmentModel>[];
  List<FactoryEquipmentModel> _initialMovingEquipment = <FactoryEquipmentModel>[];
  bool _isMoving = false;
  Coordinates _startMovingLocation;
  Coordinates _startDragLocation;

  GameBloc _bloc;

  double _cubeSize = 30.0;
  double _scaleEnd;
  Offset _startPoint;

  static const double _maxZoomLimit = 40.0;
  static const double _minZoomLimit = 0.25;


  @override
  Widget build(BuildContext context) {
    _bloc = GameProvider.of(context);

    return GestureDetector(
      onScaleStart: (ScaleStartDetails ssd){
        final Offset _s = (ssd.focalPoint - _bloc.gameCameraPosition.position) / _bloc.gameCameraPosition.scale + Offset(_cubeSize / 2, _cubeSize / 2);
        final Coordinates _coordinate = Coordinates((_s.dx / _cubeSize).floor(),(_s.dy / _cubeSize).floor());

        if(_selected.contains(_coordinate)){
          _isMoving = true;
          _movingEquipment.addAll(_selected.where((Coordinates c) => _bloc.equipment.firstWhere((FactoryEquipmentModel fe) => fe.coordinates == c && fe.isMutable, orElse: () => null) != null).map((Coordinates c) => _bloc.equipment.firstWhere((FactoryEquipmentModel fe) => fe.coordinates == c, orElse: () => null)));

          if(_bloc.copyMode == CopyMode.move){
            _movingEquipment.forEach((FactoryEquipmentModel fem)=> _bloc.equipment.remove(fem));
          }

          _initialMovingEquipment.addAll(_movingEquipment);
          _startMovingLocation = _coordinate;
        }else{
          _isMoving = false;
          _scaleEnd = _bloc.gameCameraPosition.scale;
          _startPoint = ssd.focalPoint - _bloc.gameCameraPosition.position;
        }
      },
      onScaleEnd: (ScaleEndDetails sed){
        if(_isMoving && _movingEquipment.isNotEmpty){
          _initialMovingEquipment.clear();

          _selected.clear();
          _movingEquipment.removeWhere((FactoryEquipmentModel fem) => fem.coordinates.x < 0 || fem.coordinates.y < 0 || fem.coordinates.x > _bloc.mapWidth || fem.coordinates.y > _bloc.mapHeight);

          _selected.addAll(_movingEquipment.map((FactoryEquipmentModel fem) => fem.coordinates));
          _bloc.equipment.removeWhere((FactoryEquipmentModel fem) => _selected.contains(fem.coordinates));

          _bloc.equipment.addAll(_movingEquipment);
          _movingEquipment.clear();

          _isMoving = false;
        }

        _findPortalPartner();
      },
      onScaleUpdate: (ScaleUpdateDetails sud){
        final Offset _s = (sud.focalPoint - _bloc.gameCameraPosition.position) / _bloc.gameCameraPosition.scale + Offset(_cubeSize / 2, _cubeSize / 2);
        final Coordinates _coordinate = Coordinates((_s.dx / _cubeSize).floor(),(_s.dy / _cubeSize).floor());

        if(sud.scale != 1.0){
          _isMoving = false;
        }

        if(_isMoving){
          print((_coordinate - _startMovingLocation).toMap());

          _movingEquipment = _initialMovingEquipment.map((FactoryEquipmentModel fem) => fem.copyWith(coordinates: fem.coordinates + (_coordinate - _startMovingLocation))).toList();
        }else{
          _bloc.gameCameraPosition.scale = (_scaleEnd * sud.scale).clamp(_minZoomLimit, _maxZoomLimit);

          final Offset normalizedOffset = _startPoint / _scaleEnd;
          final Offset _offset = sud.focalPoint - normalizedOffset * _bloc.gameCameraPosition.scale;

          _bloc.gameCameraPosition.position = _offset;
        }
      },
      onLongPress: _selected.clear,
      onLongPressMoveUpdate: (LongPressMoveUpdateDetails lpmud){
        final Offset _s = (lpmud.globalPosition - _bloc.gameCameraPosition.position) / _bloc.gameCameraPosition.scale + Offset(_cubeSize / 2, _cubeSize / 2);
        final Coordinates _coordinate = Coordinates((_s.dx / _cubeSize).floor(),(_s.dy / _cubeSize).floor());


        if(_coordinate.x >= 0 && _coordinate.y >= 0 && _coordinate.x <= _bloc.mapWidth && _coordinate.y <= _bloc.mapHeight){
          if(_bloc.selectMode == SelectMode.box){
            _startDragLocation ??= _coordinate;

            _selected.clear();

            int _moveX = _startDragLocation.x - _coordinate.x;
            int _moveY = _startDragLocation.y - _coordinate.y;

            for(int i = 0; i <= _moveX.abs(); i++){
              for(int j = 0; j <= _moveY.abs(); j++){
                _selected.add(_startDragLocation + Coordinates(_moveX.isNegative ? i : -i, _moveY.isNegative ? j : -j));
              }
            }
          }else if(_bloc.selectMode == SelectMode.freestyle){
            if(!_selected.contains(_coordinate)){
              _selected.add(_coordinate);
            }
          }
        }

        _bloc.selectedTiles = _selected;
      },
      onLongPressEnd: (LongPressEndDetails details){
        _startDragLocation = null;
      },
      onTapUp: (TapUpDetails tud){
        int _tapTime = DateTime.now().millisecondsSinceEpoch;

        final Offset _s = (tud.globalPosition - _bloc.gameCameraPosition.position) / _bloc.gameCameraPosition.scale + Offset(_cubeSize / 2, _cubeSize / 2);
        final Coordinates _coordinate = Coordinates((_s.dx / _cubeSize).floor(),(_s.dy / _cubeSize).floor());
        final FactoryEquipmentModel _se = _bloc.equipment.firstWhere((FactoryEquipmentModel fe) => fe.coordinates == _coordinate, orElse: () => null);

        if(_se != null && _tapTime - _lastTap < doubleTapDuration && _se.isMutable && _lastTapLocation == _coordinate && _movingEquipment.isEmpty){
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text('${equipmentTypeToString(_se.type)} copied!',
              style: Theme.of(context).textTheme.button.copyWith(color: Colors.white)
            ),
            duration: Duration(milliseconds: 350),
            behavior: SnackBarBehavior.floating,
          ));
          _selected.clear();
          _movingEquipment.add(_se);
          if(_bloc.copyMode == CopyMode.move){
            _bloc.equipment.remove(_se);
          }

          _findPortalPartner();
        }else if(_movingEquipment.isNotEmpty){
          if(_se == null && _coordinate.x >= 0 && _coordinate.y >= 0 && _coordinate.x <= _bloc.mapWidth && _coordinate.y <= _bloc.mapHeight){
            Scaffold.of(context).showSnackBar(SnackBar(
              content: Text('${equipmentTypeToString(_movingEquipment.first.type)} pasted!',
                style: Theme.of(context).textTheme.button.copyWith(color: Colors.white)
              ),
              duration: Duration(milliseconds: 350),
              behavior: SnackBarBehavior.floating,
            ));
            _bloc.equipment.add(_movingEquipment.first.copyWith(coordinates: _coordinate));
            _selected.add(_coordinate);
            _tapTime = 0;
            _movingEquipment.clear();

            _findPortalPartner();
          }else{
            String _snackbarText;
            if(_coordinate.x >= 0 && _coordinate.y >= 0 && _coordinate.x <= _bloc.mapWidth && _coordinate.y <= _bloc.mapHeight){
              _snackbarText = 'Can\'t paste on top of existing ${equipmentTypeToString(_se.type)}!';
            }else{
              _snackbarText = 'Can\'t paste outside of the bounderies!';
            }

            Scaffold.of(context).showSnackBar(SnackBar(
              content: Text(_snackbarText, style: Theme.of(context).textTheme.button.copyWith(color: DynamicTheme.of(context).data.machineInActiveColor),),
              duration: Duration(milliseconds: 550),
              behavior: SnackBarBehavior.floating,
            ));
          }
        }else if(_selected.contains(_coordinate)){
          FactoryEquipmentModel _e = _bloc.equipment.firstWhere((FactoryEquipmentModel fe) => fe.coordinates == _coordinate, orElse: () => null);
          if(_e != null && _e is UndergroundPortal && _e.connectingPortal != null && _selected.contains(_e.connectingPortal)){
            _selected.remove(_e.connectingPortal);
          }

          _selected.remove(_coordinate);
        }else{
          final List<FactoryEquipmentModel> _selectedEquipment = _bloc.equipment.where((FactoryEquipmentModel fe) => _selected.contains(fe.coordinates)).toList();

          if(_selected.isNotEmpty && ((_selectedEquipment.isEmpty && _se != null) || (_selectedEquipment.isNotEmpty && _se == null) || !(_bloc.isSameEquipment || (_selectedEquipment.isNotEmpty && _se?.type == _selectedEquipment.first.type)))){
            _selected.clear();
          }

          if(_coordinate.x >= 0 && _coordinate.y >= 0 && _coordinate.x <= _bloc.mapWidth && _coordinate.y <= _bloc.mapHeight){
            FactoryEquipmentModel _e = _bloc.equipment.firstWhere((FactoryEquipmentModel fe) => fe.coordinates == _coordinate, orElse: () => null);
            if(_e != null && _e is UndergroundPortal && _e.connectingPortal != null && !_selected.contains(_e.connectingPortal)){
              _selected.add(_e.connectingPortal);
            }

            _selected.add(_coordinate);
          }
        }

        _lastTapLocation = _coordinate;
        _lastTap = _tapTime;
        _bloc.selectedTiles = _selected;
      },
      child: StreamBuilder<GameUpdate>(
        stream: _bloc.gameUpdate,
        builder: (BuildContext context, AsyncSnapshot<GameUpdate> snapshot){
          return CustomPaint(
            isComplex: true,
            willChange: true,
            painter: GamePainter(_bloc, _bloc.mapWidth, _bloc.mapHeight, _bloc.gameCameraPosition, _cubeSize, selectedTiles: _selected, copyMaterial: _movingEquipment, theme: ThemeProvider.of(context)),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }

  void _findPortalPartner(){
    List<UndergroundPortal> _portals = _bloc.equipment.where((FactoryEquipmentModel fem) => fem is UndergroundPortal).map<UndergroundPortal>((FactoryEquipmentModel fem) => fem).toList();

    _portals.forEach((UndergroundPortal up){
      if(up.connectingPortal != null){
        UndergroundPortal _portal = _portals.firstWhere((UndergroundPortal _up) => _up.coordinates == up.connectingPortal, orElse: () => null);

        if(_portal != null && (_portal.coordinates.x == up.coordinates.x || _portal.coordinates.y == up.coordinates.y)){

          if(_portal.coordinates.x == up.coordinates.x){
            if(_portal.coordinates.y < up.coordinates.y){
              _portal.direction = Direction.south;
              up.direction = Direction.north;
            }else{
              _portal.direction = Direction.north;
              up.direction = Direction.south;
            }
          }else{
            if(_portal.coordinates.x < up.coordinates.x){
              _portal.direction = Direction.west;
              up.direction = Direction.east;
            }else{
              _portal.direction = Direction.east;
              up.direction = Direction.west;
            }
          }
          return;
        }

        print('Portal ${up.coordinates.toMap()} lost it\'s partner!');
        up.connectingPortal = null;
      }

      print('Building portal!');
      final List<UndergroundPortal> _connectingPortal = _portals.where((UndergroundPortal fem){
        if(fem.coordinates == up.coordinates){
          return false;
        }

        bool _hasPartner = false;

        for(int i = 0; i < 32; i++){
          _hasPartner = _hasPartner || (fem.coordinates.y == up.coordinates.y - i && fem.coordinates.x == up.coordinates.x);
          _hasPartner = _hasPartner || (fem.coordinates.y == up.coordinates.y + i && fem.coordinates.x == up.coordinates.x);
          _hasPartner = _hasPartner || fem.coordinates.x == up.coordinates.x - i && fem.coordinates.y == up.coordinates.y;
          _hasPartner = _hasPartner || fem.coordinates.x == up.coordinates.x + i && fem.coordinates.y == up.coordinates.y;
        }

        return _hasPartner;
      }).toList();

      if(_connectingPortal != null){
        _connectingPortal.firstWhere((UndergroundPortal fem){
          if(fem.coordinates == up.coordinates){
            return false;
          }

          final UndergroundPortal _portal = _portals.firstWhere((UndergroundPortal _up) => _up.coordinates == fem.connectingPortal, orElse: () => null);

          if(_portal != null && (_portal.coordinates.x == fem.coordinates.x || _portal.coordinates.y == fem.coordinates.y)){
            print('Candidate is already connected! ${up.coordinates.toMap()} - ${fem.coordinates.toMap()}');
            return false;
          }

          print('Connecting portal is: ${fem}');
          print('Connection length: ${up.toMap()} - ${fem.coordinates.toMap()}');
          print('Connection length: ${up.coordinates.x - fem.coordinates.x}');

          fem.connectingPortal = up.coordinates;
          up.connectingPortal = fem.coordinates;

          final Color _lineColor = RandomColor().randomColor();

          fem.lineColor = _lineColor;
          up.lineColor = _lineColor;

          print('Portal ${up.coordinates.toMap()} FOUND it\'s partner!');

          if(fem.coordinates.x == up.coordinates.x){
            if(fem.coordinates.y < up.coordinates.y){
              fem.direction = Direction.south;
              up.direction = Direction.north;
            }else{
              fem.direction = Direction.north;
              up.direction = Direction.south;
            }
          }else{
            if(fem.coordinates.x < up.coordinates.x){
              fem.direction = Direction.west;
              up.direction = Direction.east;
            }else{
              fem.direction = Direction.east;
              up.direction = Direction.west;
            }
          }

          if(!_selected.contains(fem.coordinates)){
            _selected.add(fem.coordinates);
          }

          return true;
        }, orElse: (){
          print('Passed all candidates ${_connectingPortal.length} but no connecting portal was found!');
          return null;
        });
      }else{
        print('No connecting portal!');
      }
    });
  }
}

class GamePainter extends CustomPainter{
  const GamePainter(this.bloc, this.rows, this.columns, this.camera, this.cubeSize, {this.theme = const LightGameTheme(), this.selectedTiles, this.copyMaterial, Listenable repaint}) : super(repaint: repaint);

  final int rows;
  final int columns;
  final double cubeSize;
  final GameBloc bloc;
  final GameTheme theme;

  final List<Coordinates> selectedTiles;
  final GameCameraPosition camera;
  final List<FactoryEquipmentModel> copyMaterial;


  @override
  void paint(Canvas canvas, Size size) {
    final Paint _basePaint = Paint()..color = theme.voidColor;
    canvas.drawPaint(_basePaint);

    final Matrix4 _transformMatrix = Matrix4.identity()
      ..translate(camera.position.dx, camera.position.dy)
      ..scale(camera.scale);

    canvas.transform(_transformMatrix.storage);

    canvas.drawRect(
      Rect.fromPoints(
        Offset(-cubeSize / 2, -cubeSize / 2),
        Offset(cubeSize * rows + cubeSize / 2, cubeSize * columns + cubeSize / 2)
      ),
      Paint()..color = theme.floorColor
    );

    selectedTiles.forEach((Coordinates c){
      canvas.drawRect(
        Rect.fromCircle(
          center: Offset(c.x * cubeSize, c.y * cubeSize),
          radius: cubeSize / 2
        ),
        Paint()..color = theme.selectedTileColor
      );
    });

    for(int i = 0; i < columns; i++){
      canvas.drawLine(
        Offset(-cubeSize / 2, cubeSize * i + cubeSize / 2),
        Offset(cubeSize * rows + cubeSize / 2, cubeSize * i + cubeSize / 2),
        Paint()..color = theme.separatorsColor..strokeWidth = 0.4
      );
    }

    for(int i = 0; i < rows; i++){
      canvas.drawLine(
        Offset(cubeSize * i + cubeSize / 2, -cubeSize / 2),
        Offset(cubeSize * i + cubeSize / 2, cubeSize * columns + cubeSize / 2),
        Paint()..color = theme.separatorsColor..strokeWidth = 0.4
      );
    }

    List<Coordinates> _didConnect = <Coordinates>[];

    bloc.equipment.where((FactoryEquipmentModel fe) => fe is UndergroundPortal && fe.connectingPortal != null && fe.distance != null).map<UndergroundPortal>((FactoryEquipmentModel fem) => fem).forEach((UndergroundPortal up){
      if(_didConnect.contains(up.coordinates)){
        return;
      }

      if(up.coordinates.x == up.connectingPortal.x){
        bool _goUp = up.coordinates.y > up.connectingPortal.y;

        for(int i = 0; i < (up.distance + 1); i++){
          canvas.drawRect(
            Rect.fromCircle(
              center: Offset(up.coordinates.x * cubeSize, (up.coordinates.y + (_goUp ? -i : i)) * cubeSize),
              radius: cubeSize / 2
            ),
            Paint()..color = up.lineColor.withOpacity(0.25)
          );
        }
      }else{
        bool _goRight = up.coordinates.x > up.connectingPortal.x;

        for(int i = 0; i < (up.distance + 1); i++){
          canvas.drawRect(
            Rect.fromCircle(
              center: Offset((up.coordinates.x + (_goRight ? -i : i)) * cubeSize, up.coordinates.y * cubeSize),
              radius: cubeSize / 2
            ),
            Paint()..color = up.lineColor.withOpacity(0.25)
          );
        }
      }

      _didConnect.add(up.connectingPortal);
    });

    bloc.equipment.forEach((FactoryEquipmentModel fe){
      fe.drawTrack(theme, Offset(fe.coordinates.x * cubeSize, fe.coordinates.y * cubeSize), canvas, cubeSize, bloc.progress);
    });

    bloc.equipment.forEach((FactoryEquipmentModel fe){
      fe.drawMaterial(theme, Offset(fe.coordinates.x * cubeSize, fe.coordinates.y * cubeSize), canvas, cubeSize, bloc.progress);
    });

    bloc.equipment.forEach((FactoryEquipmentModel fe){
      fe.drawEquipment(theme, Offset(fe.coordinates.x * cubeSize, fe.coordinates.y * cubeSize), canvas, cubeSize, bloc.progress);

      if(bloc.showArrows){
        fe.paintInfo(theme, Offset(fe.coordinates.x * cubeSize, fe.coordinates.y * cubeSize), canvas, cubeSize, bloc.progress);
      }
    });

    if(copyMaterial != null){
      copyMaterial.forEach((FactoryEquipmentModel fem){
        bool _inLimits = fem.coordinates.x >= 0 && fem.coordinates.y >= 0 && fem.coordinates.x <= bloc.mapWidth && fem.coordinates.y <= bloc.mapHeight;
        canvas.save();
        canvas.clipRect(Rect.fromCircle(center: Offset(fem.coordinates.x * cubeSize, fem.coordinates.y * cubeSize), radius: cubeSize / 2));
        fem.drawTrack(theme, Offset(fem.coordinates.x * cubeSize, fem.coordinates.y * cubeSize), canvas, cubeSize, bloc.progress);
        fem.drawEquipment(theme, Offset(fem.coordinates.x * cubeSize, fem.coordinates.y * cubeSize), canvas, cubeSize, bloc.progress);
        canvas.drawRect(Rect.fromCircle(center: Offset(fem.coordinates.x * cubeSize, fem.coordinates.y * cubeSize), radius: cubeSize / 2), Paint()..color = _inLimits ? theme.floorColor.withOpacity(0.5) : theme.machineInActiveColor.withOpacity(0.6));
        if(_inLimits){
          canvas.drawRect(Rect.fromCircle(center: Offset(fem.coordinates.x * cubeSize, fem.coordinates.y * cubeSize), radius: cubeSize / 2), Paint()..color = theme.selectedTileColor.withOpacity(0.5));
        }
        canvas.restore();
      });
    }

    bloc.getExcessMaterial.forEach((FactoryMaterialModel fm){
      if(bloc.getLastExcessMaterial.contains(fm)){
        fm.drawMaterial(Offset(fm.offsetX + fm.x * cubeSize, fm.offsetY + fm.y * cubeSize), canvas, bloc.progress, opacity: 1.0 - bloc.progress);
      }else{
        fm.drawMaterial(Offset(fm.offsetX + fm.x * cubeSize, fm.offsetY + fm.y * cubeSize), canvas, bloc.progress);
      }
    });
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) {
    return true;
  }
}