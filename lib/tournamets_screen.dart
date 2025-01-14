import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opencv/core/imgproc.dart';

import 'captured_size_image_screen.dart';
import 'colors.dart';
import 'custom_button.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:opencv/opencv.dart';
import 'package:image/image.dart' as img;
class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({Key? key}) : super(key: key);

  @override
  _TournamentsScreenState createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  String? _selectedTicketType;
  bool _colorBorder = false;
  TextEditingController _fishSpeciesController = TextEditingController();
  TextEditingController _stateController = TextEditingController();
  TextEditingController _tournamentNameController = TextEditingController();
  double? _fishSize;
  PickedFile? _fishImage;
  File? _fishModifiedImage;
  Future<PickedFile?>? _fishImageWithAngler;
  double? measuredSizeMm;
  double? measuredSizeInch;

  String? imgFilePath;
  String? imgWithAnglerPath;
  bool _rotateFishImage = false;
  Future<PickedFile?> _getImage() async {
    return await ImagePicker().getImage(source: ImageSource.gallery);
  }

  Future<Uint8List?> openCVCode(PickedFile fishImage)async{
    var res = await ImgProc.cvtColor(await fishImage.readAsBytes(), ImgProc.colorBGR2GRAY);
    res = await ImgProc.gaussianBlur(res, [7, 7], 0);
    var res2 = await ImgProc.houghCirclesCoordinates(await res,
        method: 3,
        dp: 2.1,
        minDist: 1,
        param1: 37,
        param2: 95,
        minRadius: 22,
        maxRadius: 38);
    print(res2);
    img.Image? image = await img.decodeImageFile(fishImage.path);

    if(res2.length>0) {
      for(int i = 0;i<res2.length;i=i+3) {
        image = img.drawCircle(image!, x: res2[i].toInt(),
            y: res2[i+1].toInt(),
            radius: res2[i+2].toInt(),
            color: img.ColorRgb8(255, 0, 0));
      }
    }
    var res3  =  img.encodePng(image!);//image.getBytes();

    print("Response from houghCirclesCoordinates:$res3");
    return res3;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Measurement Screen',
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Fish Size',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 15),
                      Card(
                          margin: EdgeInsets.zero,
                          color: MyColors.light_grey,
                          clipBehavior: Clip.antiAlias,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                          child: GestureDetector(
                            onTap: () {
                              _getImage().then((value) async{
                                _fishImage = value;
                                final coords = await openCVCode(_fishImage!);
                                setState(() {});
                                if (value != null) {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              CapturedSizeImage(
                                                imageFile: coords,//File(value.path),
                                                coords: []),
                                              )).then((value) async {
                                    if (value != null && value['submit']) {
                                      measuredSizeMm = value['measuredSizeMm'];
                                      measuredSizeInch =
                                          value['measuredSizeInch'];

                                      imgFilePath = value['imgFilePath'];
                                      _fishModifiedImage = File(imgFilePath!);
                                      var decodedImage =
                                          await decodeImageFromList(
                                              _fishModifiedImage!
                                                  .readAsBytesSync());
                                      print(decodedImage.width);
                                      print(decodedImage.height);
                                      if (decodedImage.height >
                                          decodedImage.width) {
                                        _rotateFishImage = true;
                                      } else {
                                        _rotateFishImage = false;
                                      }
                                      setState(() {});
                                    }
                                  });
                                }
                              });
                            },
                            child: Container(
                                height: 200,
                                width: MediaQuery.of(context).size.width,
                                child: imgFilePath != null
                                    ? RotatedBox(
                                        quarterTurns: _rotateFishImage ? 3 : 0,
                                        child: Image.file(
                                          File(imgFilePath!),
                                          fit: _rotateFishImage
                                              ? BoxFit.fill
                                              : BoxFit.cover,
                                          height: double.infinity,
                                          width: double.infinity,
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                              'assets/images/cloud_upload.png'),
                                          SizedBox(height: 10),
                                          RichText(
                                              text: TextSpan(children: [
                                            TextSpan(
                                              text: 'Click to ',
                                              style: TextStyle(
                                                  color: Colors.black),
                                            ),
                                            TextSpan(
                                              text: 'Upload ',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(
                                              text: 'Fish Image & ',
                                              style: TextStyle(
                                                  color: Colors.black),
                                            ),
                                            TextSpan(
                                              text: 'Measure',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ]))
                                        ],
                                      )),
                          )),
                      SizedBox(height: 15),
                      Card(
                          margin: EdgeInsets.zero,
                          color: MyColors.light_grey,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  measuredSizeMm == null
                                      ? '0 mm'
                                      : '${measuredSizeMm!.toStringAsFixed(2)} mm',
                                  style: TextStyle(
                                      color: measuredSizeMm == null
                                          ? Colors.grey
                                          : Colors.black),
                                )),
                          )),
                      SizedBox(height: 15),
                      Card(
                          margin: EdgeInsets.zero,
                          color: MyColors.light_grey,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  measuredSizeInch == null
                                      ? '0 inch'
                                      : '${measuredSizeInch!.toStringAsFixed(2)} inch',
                                  style: TextStyle(
                                      color: measuredSizeInch == null
                                          ? Colors.grey
                                          : Colors.black),
                                )),
                          )),
                      SizedBox(height: 30),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Fish Image with Angler',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 15),
                      Card(
                          margin: EdgeInsets.zero,
                          color: MyColors.light_grey,
                          elevation: 0,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                          child: InkWell(
                            onTap: () async {
                              _fishImageWithAngler = _getImage();
                              setState(() {});
                            },
                            child: SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: _fishImageWithAngler != null
                                  ? FutureBuilder<PickedFile?>(
                                      future: _fishImageWithAngler!,
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          imgWithAnglerPath =
                                              snapshot.data!.path;
                                          return CustomPaint(
                                            child: Image.file(
                                              File(snapshot.data!.path),
                                              fit: BoxFit.cover,
                                            ),
                                            // foregroundPainter: _rect != null
                                            //     ? MyRectPainter(rect: _rect!)
                                            //     : null,
                                          );
                                        } else {
                                          return Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                  'assets/images/cloud_upload.png'),
                                              SizedBox(height: 10),
                                              RichText(
                                                  text: TextSpan(children: [
                                                TextSpan(
                                                  text: 'Click to ',
                                                  style: TextStyle(
                                                      color: Colors.black),
                                                ),
                                                TextSpan(
                                                  text: 'Upload ',
                                                  style: TextStyle(
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                TextSpan(
                                                  text:
                                                      'Fish with Angler Image',
                                                  style: TextStyle(
                                                      color: Colors.black),
                                                ),
                                              ]))
                                            ],
                                          );
                                        }
                                      },
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                            'assets/images/cloud_upload.png'),
                                        SizedBox(height: 10),
                                        RichText(
                                            text: TextSpan(children: [
                                          TextSpan(
                                            text: 'Click to ',
                                            style:
                                                TextStyle(color: Colors.black),
                                          ),
                                          TextSpan(
                                            text: 'Upload ',
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: 'Fish with Angler Image',
                                            style:
                                                TextStyle(color: Colors.black),
                                          ),
                                        ]))
                                      ],
                                    ),
                            ),
                          )),
                      SizedBox(height: 15),
                      CustomButton(
                        color: Theme.of(context).primaryColor,
                        onTap: () {
                          File(imgFilePath!);
                          File(imgWithAnglerPath!);
                        },
                        title: 'Submit',
                        width: 150,
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      )),
    );
  }
}
