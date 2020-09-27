within Buildings.Examples.VAVReheat;
model testbed
  "Variable air volume flow system with terminal reheat and five thermal zones. This allows external
   agents to set the supervisory control set points."
  extends Modelica.Icons.Example;
  extends Buildings.Examples.VAVReheat.BaseClasses.PartialOpenLoop(
    heaCoi(show_T=true),
    cooCoi(show_T=true));

  Modelica.Blocks.Interfaces.RealInput TSupSetHea "AHU hetaing coil Air Setpoint";

  Modelica.Blocks.Interfaces.RealInput CorTRooSetCoo = 303.15 "Corridor Cooling Air Set Point. Default Value = 303.15";
  Modelica.Blocks.Interfaces.RealInput CorTRooSetHea = 285.15 "Corridor Heating Air Set Point. Default Value = 285.15";
  Modelica.Blocks.Interfaces.RealInput NorTRooSetCoo = 303.15 "North Zone Cooling Air Set Point. Default Value = 303.15";
  Modelica.Blocks.Interfaces.RealInput NorTRooSetHea = 285.15 "North Zone Heating Air Set Point. Default Value = 285.15";
  Modelica.Blocks.Interfaces.RealInput SouTRooSetCoo = 303.15 "South Zone Cooling Air Set Point. Default Value = 303.15";
  Modelica.Blocks.Interfaces.RealInput SouTRooSetHea = 285.15 "South Zone Heating Air Set Point. Default Value = 285.15";
  Modelica.Blocks.Interfaces.RealInput EasTRooSetCoo = 303.15 "East Zone Cooling Air Set Point. Default Value = 303.15";
  Modelica.Blocks.Interfaces.RealInput EasTRooSetHea = 285.15 "East Zone Heating Air Set Point. Default Value = 285.15";
  Modelica.Blocks.Interfaces.RealInput WesTRooSetCoo = 303.15 "West Zone Cooling Air Set Point. Default Value = 303.15";
  Modelica.Blocks.Interfaces.RealInput WesTRooSetHea = 285.15 "West Zone Heating Air Set Point. Default Value = 285.15";


  Controls.FanVFD conFanSup(xSet_nominal(displayUnit="Pa") = 410, r_N_min=yFanMin)"Controller for fan";

  Controls.ModeSelector modeSelector;

  Controls.ControlBus controlBus;

  Controls.Economizer conEco(
    dT=1,
    VOut_flow_min=0.3*m_flow_nominal/1.2,
    Ti=600,
    k=0.1) "Controller for economizer";

  Controls.DuctStaticPressureSetpoint pSetDuc(
    nin=5,
    controllerType=Modelica.Blocks.Types.SimpleController.PI,
    pMin=50) "Duct static pressure setpoint";

  Controls.CoolingCoilTemperatureSetpoint TSetCoo "Setpoint for cooling coil";

  Controls.RoomVAV conVAVCor "Controller for terminal unit corridor";
  Controls.RoomVAV conVAVSou "Controller for terminal unit south";
  Controls.RoomVAV conVAVEas "Controller for terminal unit east";
  Controls.RoomVAV conVAVNor "Controller for terminal unit north";
  Controls.RoomVAV conVAVWes "Controller for terminal unit west";

  Buildings.Controls.Continuous.LimPID heaCoiCon(
    yMax=1,
    yMin=0,
    Td=60,
    initType=Modelica.Blocks.Types.InitPID.InitialState,
    controllerType=Modelica.Blocks.Types.SimpleController.PI,
    k=0.02,
    Ti=300) "Controller for heating coil";

  Buildings.Controls.Continuous.LimPID cooCoiCon(
    reverseAction=true,
    Td=60,
    initType=Modelica.Blocks.Types.InitPID.InitialState,
    yMax=1,
    yMin=0,
    controllerType=Modelica.Blocks.Types.SimpleController.PI,
    Ti=600,
    k=0.1) "Controller for cooling coil";

  Buildings.Controls.OBC.CDL.Logical.Switch swiHeaCoi
    "Switch to switch off heating coil";

  Buildings.Controls.OBC.CDL.Logical.Switch swiCooCoi
    "Switch to switch off cooling coil";

  Buildings.Controls.OBC.CDL.Continuous.Sources.Constant coiOff(k=0)
    "Signal to switch water flow through coils off";

  Buildings.Controls.OBC.CDL.Logical.Or or2;

equation
  connect(TSupSetHea, heaCoiCon.u_s);
  connect(fanSup.port_b, dpDisSupFan.port_a);
  connect(controlBus, modeSelector.cb);
  connect(min.y, controlBus.TRooMin);
  connect(ave.y, controlBus.TRooAve);
  connect(TRet.T, conEco.TRet);
  connect(TMix.T, conEco.TMix);
  connect(conEco.TSupHeaSet, TSupSetHea);
  connect(dpDisSupFan.p_rel, conFanSup.u_m);

  connect(pSetDuc.y, conFanSup.u);
  connect(TSetCoo.TSet, cooCoiCon.u_s);
  connect(TSetCoo.TSet, conEco.TSupCooSet);
  connect(TSupSetHea, TSetCoo.TSetHea);
  connect(modeSelector.cb, TSetCoo.controlBus);
  connect(conEco.VOut_flow, VOut1.V_flow);
  connect(conEco.yOA, eco.yOut);

  connect(conVAVCor.TRoo, TRooAir.y5[1]);
  connect(conVAVSou.TRoo, TRooAir.y1[1]);
  connect(TRooAir.y2[1], conVAVEas.TRoo);
  connect(TRooAir.y3[1], conVAVNor.TRoo);
  connect(TRooAir.y4[1], conVAVWes.TRoo);
  connect(cor.yVAV, conVAVCor.yDam);
  connect(cor.yVal, conVAVCor.yVal);

  connect(conVAVSou.yDam, sou.yVAV);
  connect(conVAVSou.yVal, sou.yVal);
  connect(conVAVEas.yVal, eas.yVal);
  connect(conVAVEas.yDam, eas.yVAV);
  connect(conVAVNor.yDam, nor.yVAV);
  connect(conVAVNor.yVal, nor.yVal);
  
  connect(conVAVCor.TRooHeaSet, CorTRooSetHea);
  connect(conVAVCor.TRooCooSet, CorTRooSetCoo);
  connect(conVAVSou.TRooHeaSet, SouTRooSetHea);
  connect(conVAVSou.TRooCooSet, SouTRooSetCoo);
  connect(conVAVEas.TRooHeaSet, EasTRooSetHea);
  connect(conVAVEas.TRooCooSet, EasTRooSetCoo);
  connect(conVAVNor.TRooHeaSet, NorTRooSetHea);
  connect(conVAVNor.TRooCooSet, NorTRooSetCoo);
  connect(conVAVWes.TRooHeaSet, WesTRooSetHea);
  connect(conVAVWes.TRooCooSet, WesTRooSetCoo);

  connect(conVAVWes.yVal, wes.yVal);
  connect(wes.yVAV, conVAVWes.yDam);
  connect(occSch.tNexOcc, controlBus.dTNexOcc);
  connect(occSch.occupied, controlBus.occupied);
  connect(pSetDuc.TOut, TOut.y);
  connect(TOut.y, controlBus.TOut);
  connect(conEco.controlBus, controlBus);
  connect(modeSelector.yFan, conFanSup.uFan);
  connect(conFanSup.y, fanSup.y);
  connect(modeSelector.yFan, swiCooCoi.u2);
  connect(swiCooCoi.u1, cooCoiCon.y);
  connect(swiHeaCoi.u1, heaCoiCon.y);
  connect(coiOff.y, swiCooCoi.u3);
  connect(coiOff.y, swiHeaCoi.u3);
  connect(TSup.T, cooCoiCon.u_m);
  connect(TSup.T, heaCoiCon.u_m);
  connect(gaiHeaCoi.u, swiHeaCoi.y);
  connect(gaiCooCoi.u, swiCooCoi.y);
  connect(eco.yExh, conEco.yOA);
  connect(eco.yRet, conEco.yRet);
  connect(freSta.y, or2.u1);
  connect(or2.u2, modeSelector.yFan);
  connect(or2.y, swiHeaCoi.u2);
  connect(cor.y_actual, pSetDuc.u[1]);
  connect(sou.y_actual, pSetDuc.u[2]);
  connect(eas.y_actual, pSetDuc.u[3]);
  connect(nor.y_actual, pSetDuc.u[4]);
  connect(wes.y_actual, pSetDuc.u[5]);
end RLPPOV1;
