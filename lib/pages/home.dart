import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';

import 'package:band_names/services/socket_service.dart';
import 'package:band_names/models/band.dart';



class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  List<Band> bands = [];

  @override
  void initState() {

    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket.on('active-bands', _handleActiveBands );

    super.initState();
  }

  _handleActiveBands(dynamic payload) {

    this.bands = (payload as List)
      .map( (band) => Band.fromMap(band) )
      .toList();

      setState(() { });
      // usamos el metodo as list porque por defecto no podemos mapearlo, al mapearlo transformamos cada elemento del objet
      // al pasarlo as list ya lo mapeamos y despues de ser mapeado lo convertimos en lista

  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-bands');
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    final socketService = Provider.of<SocketService>(context);
    final server = socketService.serverStatus;

    return Scaffold(
      appBar: AppBar(
        title: Text('BandNames', style: TextStyle( color: Colors.black87 ) ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: <Widget>[
          Container(
            margin: EdgeInsets.only( right: 10 ),
            child: ( server == ServerStatus.Online ) 
                                                     ? Icon( Icons.check_circle, color: Colors.blue[300] )
                                                     : Icon( Icons.offline_bolt, color: Colors.red ),
          )
        ],
      ),
      body: Column(
        children: <Widget>[

         _showGraph(),

        Expanded(
          child: ListView.builder(
          itemCount: bands.length,
          itemBuilder: ( context, i ) => _bandTile( bands[i] )
          ),
        ),

        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon( Icons.add ),
        elevation: 1,
        onPressed: addNewBand
      ),
   );
  }

  Widget _bandTile( Band band ) {

    final socketService = Provider.of<SocketService>(context, listen: false);

    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: ( _ ) => socketService.emit('delete-band', { 'id': band.id }),
      background: Container(
        padding: EdgeInsets.only( left: 8.0 ),
        color: Colors.red,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Delete Band', style: TextStyle( color: Colors.white) ),
        )
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text( band.name.substring(0,2) ),
          backgroundColor: Colors.blue[100],
        ),
        title: Text( band.name ),
        trailing: Text('${ band.votes }', style: TextStyle( fontSize: 20) ),
        onTap: () => socketService.socket.emit( 'vote-band', { 'id': band.id } ),
      ),
    );
  }

  addNewBand() {

    final textController = new TextEditingController();
    
    if ( Platform.isAndroid ) {
      // Android
      return showDialog(
        context: context,
        builder: ( _ ) => AlertDialog(
            title: Text('New band name:'),
            content: TextField(
              controller: textController,
            ),
            actions: <Widget>[
              MaterialButton(
                child: Text('Add'),
                elevation: 5,
                textColor: Colors.blue,
                onPressed: () => addBandToList( textController.text )
              )
            ],
          ),
      );
    }

    showCupertinoDialog(
      context: context, 
      builder: ( _ ) => CupertinoAlertDialog(
          title: Text('New band name:'),
          content: CupertinoTextField(
            controller: textController,
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('Add'),
              onPressed: () => addBandToList( textController.text )
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text('Dismiss'),
              onPressed: () => Navigator.pop(context)
            )
          ],
        )
    );

  }  

  void addBandToList( String name ) {

    final socketService = Provider.of<SocketService>(context, listen: false);

    if ( name.length > 1 ) {
      // Podemos agregar
      socketService.socket.emit('add-band', { 'name': name });
      
    }


    Navigator.pop(context);

  }

 //  Mostrar Grafica

  Widget _showGraph(){


    Map<String, double> dataMap = new Map();
    // dataMap.putIfAbsent('Flutter', () => 5);
    bands.forEach((band) {
      dataMap.putIfAbsent( band.name, () => band.votes.toDouble() );
    });

    final List<Color> colorList = [

      Colors.blue[50],
      Colors.blue[200],
      Colors.pink[50],
      Colors.pink[200],
      Colors.yellow[50],
      Colors.yellow[200],

    ];

   return dataMap.isNotEmpty ?
      Container(
      width: double.infinity,
      height: 200,
      child: 
      PieChart(
        dataMap: dataMap,
        animationDuration: Duration(milliseconds: 800),
        chartLegendSpacing: 32,
        chartRadius: MediaQuery.of(context).size.width / 2,
        colorList: colorList,
        // initialAngleInDegree: 0,
        chartType: ChartType.disc,
        // ringStrokeWidth: 32,
        // centerText: "HYBRID",
        legendOptions: LegendOptions(
          // showLegendsInRow: false,
          // legendPosition: LegendPosition.right,
          showLegends: true,
          // legendShape: BoxShape.circle,
          legendTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        chartValuesOptions: ChartValuesOptions(
          showChartValueBackground: true,
          showChartValues: true,
          showChartValuesInPercentage: false,
          showChartValuesOutside: false,
        
         )
       )
    ) : LinearProgressIndicator();
          // esto porque en ios o con fernando no aparecia debido a que el column como en el listview no le decia que espacio podia usar

  }

}