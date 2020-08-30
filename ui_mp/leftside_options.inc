#undef		OPTIONS_STYLE
#undef		STYLE2_NOPOSITION
#define		OPTIONS_LEFT
#include "ui_mp/menustyle.inc"
#include "ui_mp/newframe.inc"
#undef		OPTIONS_LEFT

#undef CHOICE_TEXTSTYLE
#undef CHOICE_TEXTSIZE
#define CHOICE_TEXTSTYLE		ITEM_TEXTSTYLE_NORMAL
#define CHOICE_TEXTSIZE			TEXTSIZE_DEFAULT

#ifndef BACKGROUND_BLACK_LETTERBOX_BLURWORLD_VIS
#include "ui/overlaybg.inc"
#endif

#ifndef FRAME_TITLE_DEFAULT
#include "ui/frame.inc"
#endif

#undef	LEFTSIDE_OPTIONS_HEIGHT
#undef	LEFTSIDE_OPTIONS_WIDTH
#define LEFTSIDE_OPTIONS_HEIGHT		332
#define LEFTSIDE_OPTIONS_WIDTH		(LEFTSIDE_OPTIONS_HEIGHT * FRAME_ASPECT_RATIO)

#include "ui_mp/leftside_tabs.inc"

// Need draw the background in beteen outer and inner frame
#undef	FRAME_TAB_BG
#define FRAME_TAB_BG \
	OPTIONS_TAB_BG( OPTIONS_TAB_1_X, when( !IsInGame() && dvarBool( ui_multiplayer ) ) )

#undef	FRAME_TAB_BG_INGAME
#define FRAME_TAB_BG_INGAME \
	OPTIONS_TAB_BG( OPTIONS_TAB_1_X, when( IsInGame() || !dvarBool( ui_multiplayer ) ) )																															\

#undef FRAME_TAB_BG

NEW_FRAME( NEW_FRAME_DEFAULT_WIDTH, NEW_FRAME_DEFAULT_HEIGHT )
NEW_FRAME_TITLE( NEW_FRAME_DEFAULT_WIDTH, NEW_FRAME_DEFAULT_HEIGHT, "@MENU_SETTINGS_CAPS", 1 )

#undef	BACK_OPEN
#define BACK_OPEN if(menuisopen(blackout_3d_tv)){close blackout_3d_tv;}; exec "wait";
#ifdef PC
NEW_FRAME_BACK_BUTTON_ACTION( NEW_FRAME_DEFAULT_WIDTH, NEW_FRAME_DEFAULT_HEIGHT, BACK_OPEN; close self; )
#else //#ifdef PC
#include "ui_mp/navcontrols.inc"
#endif //#ifdef PC

#undef	CHOICE_X_START
#undef	CHOICE_Y_START
#undef	CHOICE_HORIZONTAL_ALIGN
#undef	CHOICE_VERTICAL_ALIGN
#undef	CHOICE_DVAR_EXTRA_WIDTH

#define CHOICE_HORIZONTAL_ALIGN		HORIZONTAL_ALIGN_CENTER
#define CHOICE_VERTICAL_ALIGN		VERTICAL_ALIGN_CENTER
#define CHOICE_X_START				((-LEFTSIDE_OPTIONS_WIDTH/2) - 16)
#define CHOICE_Y_START				((-LEFTSIDE_OPTIONS_HEIGHT/2) + 32)
#define CHOICE_DVAR_EXTRA_WIDTH		120

fullScreen		0
rect			0 0 640 480	HORIZONTAL_ALIGN_FULLSCREEN

OPTIONS_TABS( OP_TAB_SETTINGS )

#undef  CHOICE_SIZE_X
#define CHOICE_SIZE_X			170


// see q_shared.h language_t for loc_language values - disable subtitle options in FIGS
#undef  SHOW_SUBTITLES
#define SHOW_SUBTITLES    ( dvarint( loc_language ) == 0 || dvarint( loc_language ) == 9 || dvarint( loc_language ) == 11 )

// disable mature content for german and japanese
#undef  SHOW_MATURE
#define SHOW_MATURE       ( dvarint( loc_language ) != 3 && dvarint( loc_language ) != 11 )

#undef  SHOW_GAME_OPTIONS
#define SHOW_GAME_OPTIONS ( dvarbool( ui_multiplayer ) || SHOW_SUBTITLES || SHOW_MATURE )


FRAME_CHOICE_BUTTON_VIS_EX( 1, "@MENU_GRAPHICS_CAPS",    LOCAL_CLOSE_ALL close self; open options_graphics,                              1, ; )
FRAME_CHOICE_BUTTON_VIS_EX( 2, "@MENU_SOUND_CAPS",       LOCAL_CLOSE_ALL close self; open options_sound,                                 1, ; )
FRAME_CHOICE_BUTTON_VIS_EX( 3, "@MENU_VOICECHAT_CAPS",   LOCAL_CLOSE_ALL close self; open options_voice,                                 1, ; )
FRAME_CHOICE_BUTTON_VIS_EX( 4, "@PATCH_GAME_CAPS",       LOCAL_CLOSE_ALL close self; open options_game,                  SHOW_GAME_OPTIONS, ; )
FRAME_CHOICE_BUTTON_VIS_EX( 5, "@MENU_PERFORMANCE_CAPS", LOCAL_CLOSE_ALL close self; open options_performance,                  SHOW_GAME_OPTIONS, ; )
FRAME_CHOICE_BUTTON_VIS_EX( 6, "@MENU_MULTIPLAYER_CAPS", LOCAL_CLOSE_ALL close self; open options_multi,	( dvarbool( ui_multiplayer ) ), ; )

FRAME_CHOICE_BUTTON_VIS_EX(	        7, "@PLATFORM_DEFAULT_SYSTEM_SETTINGS_CAPS",	LOCAL_CLOSE_ALL open options_new_pc; open options_graphics_defaults,	IsInGame() && !dvarbool( ui_multiplayer ), ; )
FRAME_CHOICE_DBUTTON_FOCUS_VIS_EX(	8, "@PLATFORM_DEFAULT_SYSTEM_SETTINGS_CAPS",	;,	;,																	IsInGame() && dvarbool( ui_multiplayer ), ; )

FRAME_CHOICE_BUTTON_VIS_EX( 7, "@MENU_CREDITS_CAPS",				setdvar next_menu_name ""; open credits,					!IsInGame() && ( !dvarbool( ui_multiplayer ) ),	; )
FRAME_CHOICE_BUTTON_VIS_EX( 9, "@PLATFORM_DEFAULT_SYSTEM_SETTINGS_CAPS",	LOCAL_CLOSE_ALL open options_new_pc; open options_graphics_defaults, !IsInGame() && !dvarbool( ui_multiplayer ), ; )
FRAME_CHOICE_BUTTON_VIS_EX( 8, "@PLATFORM_DEFAULT_SYSTEM_SETTINGS_CAPS",	LOCAL_CLOSE_ALL open options_new_pc; open options_graphics_defaults, !IsInGame() && dvarbool( ui_multiplayer ), ; )

#undef		CHOICE_SIZE_X
#undef		CHOICE_SIZE_Y

#define CHOICE_SIZE_X			170
#define CHOICE_SIZE_Y			17

#define		OPTIONS_STYLE			1
#undef		STYLE2_NOPOSITION
#define STYLE2_NOPOSITION
#include "ui_mp/menustyle.inc"

#undef CHOICE_TEXTSIZE
#define CHOICE_TEXTSIZE 	TEXTSIZE_SMALL
#undef	CHOICE_TEXTALIGN
#define	CHOICE_TEXTALIGN	ITEM_ALIGN_MIDDLE_RIGHT
#undef	CHOICE_TEXT_OFFSET_X
#define CHOICE_TEXT_OFFSET_X	(-(4+CHOICE_SIZE_Y)) //22

#undef  CHOICE_DVAR_OFFSET_X
#define CHOICE_DVAR_OFFSET_X	(CHOICE_SIZE_X+20)
#undef  CHOICE_DVAR_TEXTALIGN
#define CHOICE_DVAR_TEXTALIGN	ITEM_ALIGN_MIDDLE_LEFT
#undef CHOICE_DVAR_WIDTH_OFFSET
#define CHOICE_DVAR_WIDTH_OFFSET	120
#undef CHOICE_ACTION_SOUND	
#define CHOICE_ACTION_SOUND		"uin_mouse_click_t"

#undef CHOICE_Y_START
#define CHOICE_Y_START		60

#undef CHOICE_X_START
#define CHOICE_X_START		75

#undef CHOICE_TEXTCOLOR
#define CHOICE_TEXTCOLOR	1 1 1 1

