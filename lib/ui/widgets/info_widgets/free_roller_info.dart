import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_factory/game/factory_equipment.dart';
import 'package:flutter_factory/game/model/factory_equipment_model.dart';
import 'package:flutter_factory/game/model/factory_material_model.dart';
import 'package:flutter_factory/ui/widgets/info_widgets/object_painter.dart';

class FreeRollerInfo extends StatelessWidget {
  FreeRollerInfo({Key key, @required this.equipment}) : super(key: key);

  final RotatingFreeRoller equipment;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          SizedBox(height: 24.0,),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Rotate:'),

                Row(
                  children: <Widget>[
                    RaisedButton(
                      child: Icon(Icons.chevron_left, color: equipment.rotation == 3 ? Colors.white : Colors.black87,),
                      color: equipment.rotation == 3 ? Theme.of(context).accentColor : Colors.grey,
                      onPressed: (){
                        equipment.rotation = 3;
                      },
                    ),
                    RaisedButton(
                      child: Icon(Icons.chevron_right, color: equipment.rotation == 1 ? Colors.white : Colors.black87,),
                      color: equipment.rotation == 1 ? Theme.of(context).accentColor : Colors.grey,
                      onPressed: (){
                        equipment.rotation = 1;
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          equipment.isMutable ? SizedBox.shrink() : Column(
            children: <Widget>[
              SizedBox(height: 36.0),
              Text('This ${equipmentTypeToString(equipment.type)} is part of the challenge and cannot be moved, modified or rotated!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.caption.copyWith(color: Colors.red, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 12.0),
            ],
          ),
        ],
      ),
    );
  }
}
