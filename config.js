/**
 * This is the doornode configuration file.  This file is for defining basic dosbox launch
 * configuration and setting up door modules.
 */

module.exports = {
  /**
   * Rlogin listen port
   */
  port: 513,

  /**
   * Use your terminal program to connect to this port and manually launch modules.
   */
  debugPort: 1234,

  /**
   * Dosbox launch configuration
   */
  dosbox: {
    // the path to the dosbox executable
    dosboxPath: process.env.DOSBOX_PATH || '/usr/bin/dosbox',

    // the path to the dosbox config files
    configPath: __dirname + '/dosbox',

    // the path to the dosbox drive
    drivePath: __dirname + '/dosbox/drive',

    // communication is done using a nullmodem serial port mapping in dosbox
    // define the startpoint port number.  actual port numbers will be:
    // startPort + nodeNumber
    startPort: 10000,

    // launch dosbox instances connected to Xvfb display (:99)
    headless: false
  },

  /**
   * Define your door modules here.
   */
  doors: [
  {
    name: 'LORD',
    doorCmd: 'CALL lord.bat',
    multiNode: true,
    dropFileFormat: 'DorInfo'
  },
  {
    name: 'TW2002',
    doorCmd: 'CALL tw2002.bat',
    dropFileFormat: 'DorInfo',
    multiNode: true
  },
  {
    name: 'OO2',
    doorCmd: 'CALL oo2.bat',
    dropFileFormat: 'DoorSys',
    multiNode: true,
    removeLockFile: '/doors/oo2/OONODE.DAT'
  },
  {
    name: 'DOORMUD',
    doorCmd: 'CALL runmud.bat',
    dropFileFormat: 'DorInfo',
    multiNode: true
  },
  {
    name: 'RUNMUD',
    doorCmd: 'CALL runmud.bat',
    dropFileFormat: 'DorInfo',
    multiNode: true
  },
  {
    name: 'MUDCFG',
    doorCmd: 'CALL mudcfg.bat',
    dropFileFormat: 'DorInfo',
    multiNode: true
  },
  {
    name: 'USURPER',
    doorCmd: 'CALL usurper.bat',
    dropFileFormat: 'DoorSys',
    multiNode: true
  },
  {
    name: 'DREDD',
    doorCmd: 'CALL dredd.bat',
    dropFileFormat: 'DoorSys',
    multiNode: true
  }
  ]
}
