package;

#if FEATURE_STEPMANIA
import smTools.SMFile;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import flixel.input.keyboard.FlxKey;
#if FEATURE_MULTITHREADING
import sys.thread.Mutex;
#end
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class TitleState extends MusicBeatState
{
	static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var textGroup:FlxGroup;
	var ngSpr:FlxSprite;

	var curWacky:Array<String> = [];

	var wackyImage:FlxSprite;

	var bg:FlxSprite;

	var http = new haxe.Http("https://raw.githubusercontent.com/BoloVEVO/Kade-Engine-Public/stable/version.txt");
	var returnedData:Array<String> = [];

	override public function create():Void
	{
		getBuildVer();
		#if FEATURE_MULTITHREADING
		MasterObjectLoader.mutex = new Mutex();
		#end
		Paths.clearUnusedMemory();

		FlxG.autoPause = false;

		FlxG.save.bind('funkin', 'ninjamuffin99');

		PlayerSettings.init();

		KadeEngineData.initSave();

		#if html5
		FlxG.save.data.gpuRender = false;
		#end

		KeyBinds.keyCheck();

		if (FlxG.save.data.volDownBind == null)
			FlxG.save.data.volDownBind = "NUMPADMINUS";
		if (FlxG.save.data.volUpBind == null)
			FlxG.save.data.volUpBind = "NUMPADPLUS";

		FlxG.sound.muteKeys = [FlxKey.fromString(Std.string(FlxG.save.data.muteBind))];
		FlxG.sound.volumeDownKeys = [FlxKey.fromString(Std.string(FlxG.save.data.volDownBind))];
		FlxG.sound.volumeUpKeys = [FlxKey.fromString(Std.string(FlxG.save.data.volUpBind))];

		FlxG.mouse.visible = true;

		FlxG.worldBounds.set(0, 0);

		MusicBeatState.initSave = true;

		fullscreenBind = FlxKey.fromString(Std.string(FlxG.save.data.fullscreenBind));

		Highscore.load();

		curWacky = FlxG.random.getObject(getIntroTextShit());

		trace('hello');

		// DEBUG BULLSHIT

		logoBl = new FlxSprite(-150, 1500);
		if (Main.watermarks)
		{
			logoBl.frames = Paths.getSparrowAtlas('KadeEngineLogoBumpin');
		}
		else
		{
			logoBl.y = -100;
			logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		}
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.antialiasing = FlxG.save.data.antialiasing;
		logoBl.updateHitbox();

		gfDance = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
		gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gfDance.antialiasing = FlxG.save.data.antialiasing;

		titleText = new FlxSprite(100, FlxG.height * 0.8);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.antialiasing = FlxG.save.data.antialiasing;
		titleText.animation.play('idle');
		titleText.updateHitbox();

		if (!initialized)
		{
			credGroup = new FlxGroup();
			textGroup = new FlxGroup();

			blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
			credGroup.add(blackScreen);

			credTextShit = new Alphabet(0, 0, "ninjamuffin99\nPhantomArcade\nkawaisprite\nevilsk8er", true);
			credTextShit.screenCenter();

			ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('newgrounds_logo'));
			ngSpr.visible = false;
			ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
			ngSpr.updateHitbox();
			ngSpr.screenCenter(X);
			ngSpr.antialiasing = FlxG.save.data.antialiasing;
		}

		FlxG.sound.volume = FlxG.save.data.volume;
		FlxG.sound.muted = FlxG.save.data.mute;

		super.create();

		startIntro();
	}

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;

	function startIntro()
	{
		persistentUpdate = true;

		add(gfDance);
		add(logoBl);
		add(titleText);

		FlxG.mouse.visible = true;

		if (initialized)
			skipIntro();
		else
		{
			credTextShit.visible = false;

			FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

			add(credGroup);
			add(ngSpr);

			transIn = FlxTransitionableState.defaultTransIn;
			transOut = FlxTransitionableState.defaultTransOut;

			FlxG.sound.playMusic(Paths.music(FlxG.save.data.watermark ? "ke_freakyMenu" : "freakyMenu"));
			MainMenuState.freakyPlaying = true;

			FlxG.sound.music.fadeIn(4, 0, 0.7);
			Conductor.changeBPM(102);
		}

		// credGroup.add(credTextShit);
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var firstArray:Array<String> = OpenFlAssets.getText(Paths.txt('data/introText')).split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;
	var fullscreenBind:FlxKey;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if (FlxG.keys.anyJustPressed([fullscreenBind]))
		{
			FlxG.fullscreen = !FlxG.fullscreen;
		}

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT || FlxG.mouse.justPressed;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		if (pressedEnter && !transitioning && skippedIntro)
		{
			if (FlxG.save.data.flashing)
				titleText.animation.play('press');

			FlxG.camera.flash(FlxColor.WHITE, 1);
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

			transitioning = true;

			MainMenuState.firstStart = true;
			MainMenuState.finishedFunnyMove = false;

			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				// Get current version of Kade Engine
				if (MainMenuState.updateShit)
				{
					MusicBeatState.switchState(new OutdatedSubState());
					clean();
				}
				else
				{
					MusicBeatState.switchState(new MainMenuState());
					clean();
				}
			});
		}

		if (pressedEnter && !skippedIntro)
		{
			skipIntro();
		}

		super.update(elapsed);
	}

	function getBuildVer():Void
	{
		http.onData = function(data:String)
		{
			returnedData[0] = data.substring(0, data.indexOf(';'));
			returnedData[1] = data.substring(data.indexOf('-'), data.length);
			if (!MainMenuState.buildVer.contains(returnedData[0].trim()) && !OutdatedSubState.leftState)
			{
				Debug.logInfo('New version detected: ' + returnedData[0]);
				MainMenuState.updateShit = true;
				Debug.logInfo('outdated lmao! ' + returnedData[0] + ' != ' + MainMenuState.kadeEngineVer);
				OutdatedSubState.needVer = returnedData[0];
				OutdatedSubState.currChanges = returnedData[1];
			}
			else
			{
				Debug.logInfo('Build is up to date bois.');
			}
		}

		http.onError = function(error)
		{
			Debug.logError('error: $error');
			clean();
		}

		http.request();
	}

	function createCoolText(textArray:Array<String>)
	{
		for (i in 0...textArray.length)
		{
			if (!initialized)
			{
				var money:Alphabet = new Alphabet(0, 0, textArray[i], true, false);
				money.screenCenter(X);
				money.y += (i * 60) + 200;
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String)
	{
		if (!initialized)
		{
			var coolText:Alphabet = new Alphabet(0, 0, text, true, false);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200;
			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	function deleteCoolText()
	{
		if (!initialized)
		{
			while (textGroup.members.length > 0)
			{
				credGroup.remove(textGroup.members[0], true);
				textGroup.remove(textGroup.members[0], true);
			}
		}
	}

	override function beatHit()
	{
		super.beatHit();

		logoBl.animation.play('bump', true);

		danceLeft = !danceLeft;

		if (danceLeft)
			gfDance.animation.play('danceRight');
		else
			gfDance.animation.play('danceLeft');

		switch (curBeat)
		{
			case 0:
				deleteCoolText();
			case 1:
				createCoolText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er']);
			case 3:
				addMoreText('present');
			case 4:
				deleteCoolText();
			case 5:
				if (Main.watermarks)
					createCoolText(['Kade Engine', 'by']);
				else
					createCoolText(['In Partnership', 'with']);
			case 7:
				if (Main.watermarks)
					addMoreText('KadeDeveloper');
				else
				{
					addMoreText('Newgrounds');
					if (!initialized)
						ngSpr.visible = true;
				}
			case 8:
				deleteCoolText();
				if (!initialized)
					ngSpr.visible = false;
			case 9:
				createCoolText([curWacky[0]]);
			case 11:
				addMoreText(curWacky[1]);
			case 12:
				deleteCoolText();
			case 13:
				addMoreText('Friday');
			case 14:
				addMoreText('Night');
			case 15:
				addMoreText("Funkin'");

			case 16:
				skipIntro();
				initialized = true;
		}
	}

	var skippedIntro:Bool = false;

	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			Debug.logInfo("Skipping intro...");

			remove(ngSpr);

			FlxG.camera.flash(FlxColor.WHITE, 4);
			remove(credGroup);

			FlxTween.tween(logoBl, {y: -100}, 1.4, {ease: FlxEase.expoInOut});

			logoBl.angle = -4;

			new FlxTimer().start(0.01, function(tmr:FlxTimer)
			{
				if (logoBl.angle == -4)
					FlxTween.angle(logoBl, logoBl.angle, 4, 4, {ease: FlxEase.quartInOut});
				if (logoBl.angle == 4)
					FlxTween.angle(logoBl, logoBl.angle, -4, 4, {ease: FlxEase.quartInOut});
			}, 0);

			// It always bugged me that it didn't do this before.
			// Skip ahead in the song to the drop.
			if (!initialized)
				FlxG.sound.music.time = 9400; // 9.4 seconds

			skippedIntro = true;
		}
	}
}
