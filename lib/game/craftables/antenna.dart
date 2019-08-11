import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_factory/game/model/factory_material.dart';

class Antenna extends FactoryMaterial{
  Antenna.fromOffset(Offset o) : super(o.dx, o.dy, 540.0, FactoryMaterialType.antenna, state: FactoryMaterialState.crafted);

  @override
  void drawMaterial(Offset offset, Canvas canvas, double progress, {double opacity = 1.0}){
    Paint _p = Paint();

    double _size = size * 0.8;

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    final Path _frame = Path();

    _frame.moveTo(-_size * 0.4, -_size * 0.4);

    _frame.addArc(Rect.fromPoints(
      Offset(_size * 0.3, _size * 0.8),
      Offset(-_size * 0.3, _size * 0.3),
    ), 0, -pi);

    final Path _clockHands = Path();

    _clockHands.moveTo(0.0, _size * 0.4);
    _clockHands.lineTo(_size * 0.6, -_size * 0.8);

    _clockHands.moveTo(0.0, _size * 0.4);
    _clockHands.lineTo(-_size * 0.6, -_size * 0.8);

    canvas.drawPath(_frame, _p..color = Colors.grey.withOpacity(opacity));

    _p.color = Colors.grey.withOpacity(opacity);
    _p.strokeWidth = 0.8;
    _p.style = PaintingStyle.stroke;
    canvas.drawPath(_frame, _p);
    canvas.drawPath(_clockHands, _p..strokeWidth = .4);

    _p.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-_size * 0.6, -_size * 0.8), 0.8, _p);
    canvas.drawCircle(Offset(_size * 0.6, -_size * 0.8), 0.8, _p);

    canvas.restore();
  }

  @override
  Map<FactoryRecipeMaterialType, int> getRecipe() {
    return <FactoryRecipeMaterialType, int>{
      FactoryRecipeMaterialType(FactoryMaterialType.diamond, state: FactoryMaterialState.spring): 4,
      FactoryRecipeMaterialType(FactoryMaterialType.iron): 1,
    };
  }
}