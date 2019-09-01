import 'package:flutter/material.dart';
import 'package:flutter_factory/game/factory_equipment.dart';
import 'package:flutter_factory/game/model/factory_material_model.dart';
import 'package:flutter_factory/ui/widgets/info_widgets/object_painter.dart';

class CrafterOptionsWidget extends StatefulWidget {
  CrafterOptionsWidget({@required this.crafter, this.progress = 0.0, Key key}) : super(key: key);

  final List<Crafter> crafter;
  final double progress;

  @override
  _CrafterOptionsWidgetState createState() => _CrafterOptionsWidgetState();
}

class _CrafterOptionsWidgetState extends State<CrafterOptionsWidget> {
  bool _recepiesOpen = false;

  @override
  Widget build(BuildContext context) {
    Crafter _showFirst = widget.crafter.first;
    Map<FactoryRecipeMaterialType, int> _craftMaterial = FactoryMaterialModel.getRecipeFromType(_showFirst.craftMaterial);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: <Widget>[
          ExpansionPanelList(
            expansionCallback: (int clicked, bool open){
              setState(() {
                _recepiesOpen = !_recepiesOpen;
              });
            },
            children: <ExpansionPanel>[
              ExpansionPanel(
                headerBuilder: (BuildContext context, bool isExpanded){
                  return Container(
                    margin: const EdgeInsets.all(12.0),
                    height: 80.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              child: Text('${factoryMaterialToString(_showFirst.craftMaterial)}',
                                style: Theme.of(context).textTheme.subtitle,
                              ),
                            ),
                            SizedBox(height: 12.0,),
                            Row(
                              children: _craftMaterial.keys.map((FactoryRecipeMaterialType fmrt){
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Row(
                                    children: <Widget>[
                                      Container(
                                        child: CustomPaint(
                                          painter: ObjectPainter(
                                            widget.progress,
                                            material: FactoryMaterialModel.getFromType(fmrt.materialType)..state = fmrt.state,
                                            scale: 4.0
                                          ),
                                        ),
                                      ),

                                      SizedBox(width: 16.0,),
                                      Text('x ${_craftMaterial[fmrt]}', style: Theme.of(context).textTheme.caption,)
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: CustomPaint(
                            painter: ObjectPainter(
                              widget.progress,
                              scale: 6.0,
                              material: FactoryMaterialModel.getFromType(_showFirst.craftMaterial),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                body: Column(
                  children: FactoryMaterialType.values.where((FactoryMaterialType fmt) => !FactoryMaterialModel.isRaw(fmt)).map((FactoryMaterialType fmt){
                    Map<FactoryRecipeMaterialType, int> _recepie = FactoryMaterialModel.getRecipeFromType(fmt);

                    return InkWell(
                      onTap: (){
                        widget.crafter.forEach((Crafter c){
                          c.changeRecipe(fmt);
                        });

                        setState(() {
                          _recepiesOpen = false;
                        });
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(8.0),
                        height: 80.0,
                        foregroundDecoration: BoxDecoration(
                          color: fmt == widget.crafter.first.craftMaterial ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                          border: fmt == widget.crafter.first.craftMaterial ? Border.all(color: Colors.blue) : null
                        ),
                        decoration: BoxDecoration(
                          color: fmt.index % 2 == 0 ? Colors.white : Colors.grey.shade100,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      child: Text('${factoryMaterialToString(fmt)}',
                                        style: Theme.of(context).textTheme.subtitle,
                                      ),
                                    ),
                                    SizedBox(height: 12.0,),
                                    Row(
                                      children: _recepie.keys.map((FactoryRecipeMaterialType fmrt){
                                        return Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 12.0),
                                          child: Row(
                                            children: <Widget>[
                                              Container(
                                                child: CustomPaint(
                                                  painter: ObjectPainter(
                                                    widget.progress,
                                                    material: FactoryMaterialModel.getFromType(fmrt.materialType)..state = fmrt.state,
                                                    scale: 2.5
                                                  ),
                                                ),
                                              ),

                                              SizedBox(width: 16.0,),
                                              Text('x ${_recepie[fmrt]}', style: Theme.of(context).textTheme.caption,)
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                                Container(
                                  transform: Matrix4.translationValues(-32.0, 0.0, 0.0),
                                  margin: const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: CustomPaint(
                                    painter: ObjectPainter(
                                      widget.progress,
                                      material: FactoryMaterialModel.getFromType(fmt),
                                      scale: 3.0
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      ),
                    );
                  }).toList(),
                ),
                canTapOnHeader: true,
                isExpanded: _recepiesOpen
              )
            ],
          ),
          SizedBox(height: 28.0),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Craft speed:'),
              DropdownButton<int>(
                value: _showFirst.tickDuration,
                onChanged: (int fmt){
                  widget.crafter.forEach((Crafter c) => c.tickDuration = fmt);
                },
                items: List<int>.generate(8, (int i) => i + 1).map((int fmt){
                  return DropdownMenuItem<int>(
                    value: fmt,
                    child: Container(
                      margin: const EdgeInsets.all(12.0),
                      child: Text('$fmt')
                    ),
                  );
                }).toList(),
              )
            ],
          ),
          SizedBox(height: 28.0),
          Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Craft queue:'),
              Column(
                children: FactoryMaterialType.values.where((FactoryMaterialType type){
                  return _showFirst.objects.where((FactoryMaterialModel _fm) => _fm.type == type).isNotEmpty;
                }).map((FactoryMaterialType fmt){
                  return Chip(
                    label: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 24.0),
                                  child: CustomPaint(
                                    painter: ObjectPainter(
                                      widget.progress,
                                      material: FactoryMaterialModel.getFromType(fmt)
                                    ),
                                  ),
                                ),
                                Text('${factoryMaterialToString(fmt)}'),
                              ],
                            ),
                            Container(
                              margin: const EdgeInsets.only(left: 4.0),
                              height: 26.0,
                              width: 96.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
                                color: Colors.grey.shade800
                              ),
                              child: Center(child: Text('${_showFirst.objects.where((FactoryMaterialModel _fm) => _fm.type == fmt).length}', style: TextStyle(color: Colors.white),))
                            ),
                          ],
                        ),

                        FactoryMaterialModel.isRaw(fmt) ? Row(
                          children: FactoryMaterialState.values.where((FactoryMaterialState fms) => fms.index < 4).map((FactoryMaterialState states){
                            return Row(
                              children: <Widget>[
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 24.0),
                                  child: CustomPaint(
                                    painter: ObjectPainter(
                                      widget.progress,
                                      material: FactoryMaterialModel.getFromType(fmt)..state = states
                                    ),
                                  ),
                                ),
                                Text('${_showFirst.objects.where((FactoryMaterialModel _fm) => _fm.type == fmt && _fm.state == states).length}'),
                              ],
                            );
                          }).toList(),
                        ) : SizedBox.shrink()
                      ],
                    ),
                  );
                }).toList(),
              )
            ],
          ),
          SizedBox(height: 28.0),
        ],
      ),
    );
  }
}
