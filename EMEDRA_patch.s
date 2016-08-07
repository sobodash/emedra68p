*
* EMEDRA_patch.s (c)1996 ずうやん
*
* 公開する時は、下の行を注釈にしてからアセンブルすること
*DEBUG		equ	1

	.include	doscall.mac
	.include	iocscall.mac

NOP_code	equ	$4e71		* nop コード
RTS_code	equ	$4e75		* rts コード
JSR_code	equ	$4eb9		* jsr コード

	.text
	.even

*＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠
*＠
*＠ ・パッチ常駐部
*＠
*＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠

**********************************************************************
* 戦闘高速化パッチ
* a6以外は破壊可能
*
* [ひらがな]または[SHIFT]のみ：高速
* 両方押し：低速
**********************************************************************
battle_patch:
	move.w	$810.w,d1		* シフト系キーの状態を得る
*
	move.l	$0018(a6),d0
	beq	1f
*戦闘用タイマー
	subq.l	#1,d0			* タイマーカウンタ－１（従来の処理）
	btst.l	#$0,d1			* [SHIFT]が押されていたら、
	beq	@f
	bchg.l	#$d,d1			* [ひらがな]を逆転
@@:
	btst.l	#$d,d1			* [ひらがな]が押されていたら、ノーウエイト
	beq	@f
	moveq.l	#0,d0			* タイマーカウンタの残りを強制的に０にする
@@:
	move.l	d0,$0018(a6)
1:
*ビジュアル用タイマー：ここは、従来通りの処理
	move.l	$001c(a6),d0
	beq	@f
	subq.l	#1,d0
	move.l	d0,$001c(a6)
@@:
	rts

**********************************************************************
* コンフィグファイルをすげかえるパッチ
**********************************************************************
config_patch:
	movem.l	a0-a5,-(sp)
	lea.l	sysdata_path_check_mes(pc),a4
	lea.l	sysdata_path(pc),a5
1:
	lea.l	set_path_buf(pc),a1	* パス名を登録するバッファ
@@:
	move.b	(a4)+,(a1)+
	bne	@b
*
	subq.w	#1,a1
	move.b	#'=',(a1)+
	lea.l	emedra_all_path(pc),a0
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*
	subq.w	#1,a1
@@:
	move.b	(a5)+,(a1)+
	bne	@b
*
	pea.l	set_path_buf(pc)
	movea.l	compare_path_name_address(pc),a0
	jsr	(a0)			* パスを登録するサブルーチンを呼ぶ
	addq.w	#4,sp
*
	cmpi.b	#$ff,(a4)
	bne	1b
*
	movea.l	start_a0_backup(pc),a0
	adda.w	#$80,a0			* a0.l=EMEDRA_patch.xの起動パス格納アドレス
	lea.l	config_file_name(pc),a1
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*
	subq.w	#1,a1
	lea.l	config_name(pc),a0
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*
	clr.l	-(sp)
	pea.l	config_file_name(pc)
	DOS	_OPEN			* $ff3d
	addq.w	#8,sp
*
	movem.l	(sp)+,a0-a5
	rts

compare_path_name_address:
	.ds.l	1

**********************************************************************
* スクロール高速化パッチ
* d0は破壊可能
**********************************************************************
scroll_patch:
	move.w	$810.w,d0		* シフト系キーの状態を得る
	btst.l	#$0,d0			* [SHIFT]が押されていたら、倍速
	beq	@f
*
	lsr.b	#1,d1
@@:
	btst.l	#$e,d0			* [全角]が押されていたら、倍速
	beq	@f
*
	lsr.b	#1,d1
@@:
	ori.w	#$0700,d1
	rts

**********************************************************************
* 高速化のための、[ひらがな][全角]キーLED変更を禁止する
**********************************************************************
led_patch:
	cmpi.b	#5,d1			* [ひらがな]か？
	beq	@f
	cmpi.b	#6,d1			* [全角]か？
	beq	@f
	IOCS	_LEDMOD
@@:
	rts

**********************************************************************
* 経験値を２倍にする
**********************************************************************
exp_patch:
	lsl.l	#1,d0			* ２倍にする
	move.l	a0,-(sp)
	movea.l	exp_address(pc),a0
	move.l	d0,(a0)
	move.l	(sp)+,a0
	rts

exp_address:
	.ds.l	1			* 足し込む経験値を保存するアドレス

**********************************************************************
* オープニング：パス相対化
**********************************************************************
opening_open_patch:
	move.w	$000e(a6),-(sp)		* オープンモード
	move.l	$0008(a6),d0		* ファイル名パス
	movem.l	a0-a1,-(sp)		* レジスタ保存
	movea.l	d0,a0
	cmpi.b	#'\',2(a0)
	bne	1f
*
	addq.w	#3,a0
	move.l	a0,d0
	movea.l	start_a0_backup(pc),a0
	adda.w	#$80,a0			* a0.l=EMEDRA_patch.xの起動パス格納アドレス
	lea.l	file_name_buf(pc),a1	* ファイル名を登録するバッファ
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*
	subq.w	#1,a1
	movea.l	d0,a0
@@:
	move.b	(a0)+,(a1)+
	bne	@b
	move.l	#file_name_buf,d0
1:
	movem.l	(sp)+,a0-a1		* レジスタ復帰
	move.l	d0,-(sp)
	DOS	_OPEN
	addq.w	#6,sp
*元々の処理
	unlk	a6
	rts

**********************************************************************
* ミュージックモード：パス相対化
**********************************************************************
music_mode_open_patch:
	move.w	$000e(a6),-(sp)		* オープンモード
	move.l	$0008(a6),d0		* ファイル名パス
	movem.l	a0-a1,-(sp)		* レジスタ保存
	movea.l	d0,a0
	cmpi.b	#'\',(a0)
	bne	1f
*
	addq.w	#1,a0
	move.l	a0,d0
	movea.l	start_a0_backup(pc),a0
	adda.w	#$80,a0			* a0.l=EMEDRA_patch.xの起動パス格納アドレス
	lea.l	file_name_buf(pc),a1	* ファイル名を登録するバッファ
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*
	subq.w	#1,a1
	movea.l	d0,a0
@@:
	move.b	(a0)+,(a1)+
	bne	@b
	move.l	#file_name_buf,d0
1:
	movem.l	(sp)+,a0-a1		* レジスタ復帰
	move.l	d0,-(sp)
	DOS	_OPEN
	addq.w	#6,sp
*元々の処理
	unlk	a6
	rts


*＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠
*＠
*＠ ・メインプログラム
*＠
*＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠

**********************************************************************
* 初期処理
**********************************************************************
emedra_patch:
	lea.l	user_sp(pc),sp
	move.l	8(a0),himem_pointer	* メモリ上限アドレス退避
	move.l	a0,start_a0_backup	* a0 を保存しておく
	lea.l	$0010(a0),a0
	suba.l	a0,a1
	move.l	a1,-(sp)
	move.l	a0,-(sp)
	DOS	_SETBLOCK		* $ff4a
	addq.w	#8,sp
	tst.l	d0
	bmi	setblock_error		* SETBLOCK失敗
*タイトル表示
	pea.l	title_mes(pc)
	DOS	_PRINT
	addq.w	#4,sp

**********************************************************************
* コマンドライン解析
**********************************************************************
	tst.b	(a2)+			* ここまで a2 は壊さないように
	beq	1f
ifdef	DEBUG
	pea.l	command_line_mes(pc)
	DOS	_PRINT
	addq.w	#4,sp
	move.l	a2,-(sp)
	DOS	_PRINT
	addq.w	#4,sp
	pea.l	cr_mes(pc)
	DOS	_PRINT
	addq.w	#4,sp
	bra	@f
command_line_mes:
	.dc.b	'コマンドライン：',0
	.even
@@:
endif
	bsr	switch_check		* コマンドラインを解析
1:
*パス名は指定されていたか
	move.b	emedra_path_set_flag(pc),d0
	bne	@f
*起動パスをインストールパスとして登録する
	movea.l	start_a0_backup(pc),a2
	adda.w	#$80,a2			* a2.l=EMEDRA_patch.xの起動パス格納アドレス
	bsr	emedra_path_set
@@:
**********************************************************************
* コンフィグファイルの読み込み
**********************************************************************
	bsr	config_file

**********************************************************************
* ミュージックドライバを常駐させる
**********************************************************************
	bsr	mdevice_keep

**********************************************************************
* タイトル表示
**********************************************************************
ifdef	DEBUG
	bsr	title_print
endif

**********************************************************************
* オープニングモードかどうか
**********************************************************************
	move.b	opening_switch_flag(pc),d0
	bne	opening_exec

**********************************************************************
* ミュージックモードかどうか
**********************************************************************
	move.b	music_mode_switch_flag(pc),d0
	bne	music_mode_exec

**********************************************************************
* プログラムの読み込み
**********************************************************************
*カレントドライブの変更
	lea.l	emedra_all_path(pc),a0	* 格納パス
	moveq.l	#0,d0
	move.b	(a0),d0
	andi.b	#$1f,d0
	subq.b	#1,d0			* A=0,B=1…
	move.w	d0,-(sp)
	DOS	_CHGDRV			* $ff0e
	addq.w	#2,sp
	bmi	program_load_error	* カレント移動エラー
*パスの変更
	lea.l	exe_load_path(pc),a1	* ファイル名作成領域
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*
	subq.w	#1,a1
	lea.l	emedra_path(pc),a0	* 'EMEDRA\'
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*
	pea.l	exe_load_path(pc)
	DOS	_CHDIR			* $ff3b
	addq.w	#4,sp
	bmi	program_load_error	* カレント移動エラー

*読み込み
	clr.l	-(sp)			* 環境は親と同じ
	pea.l	emedra_command_line(pc)	* コマンドライン
	pea.l	emedra_exe_name(pc)	* ファイル名
	move.w	#$0001,-(sp)		* ロードのみ
	DOS	_EXEC			* $ff4b
	lea.l	14(sp),sp
	tst.l	d0
	bmi	program_load_error	* 読み込みエラー
	bsr	exec_extract		* LZX圧縮チェック＆解凍
	lea.l	$100(a0),a0
	move.l	a0,program_top_address		* 先頭アドレスを保存
	move.l	a4,program_exec_address		* 実行アドレスを保存

**********************************************************************
* パッチを当てる
**********************************************************************
*キーLED状態を保存
	IOCS	_B_SFTSNS
	lsr.w	#8,d0
	bclr.l	#7,d0
	move.b	d0,key_led_backup
	move.b	d0,key_led_new
*
* 必ず当てるパッチ
*
	lea.l	patch_data_table_default(pc),a0
	bsr	memory_patch		* パッチ実行
*
* コンフィグファイルパッチ
*
	lea.l	patch_data_table_path_1(pc),a0
	bsr	memory_patch		* パッチアドレス決定
	movea.l	last_patch_address(pc),a0
	subq.w	#8,a0			* サブルーチンの先頭アドレス
	move.l	a0,compare_path_name_address
*
	lea.l	patch_data_table_path_2(pc),a0
	bsr	memory_patch		* パッチアドレス決定
	movea.l	last_patch_address(pc),a0
	move.l	#config_patch,(a0)
*
* どこでもマップパッチ
*
	move.b	ex_map_flag(pc),d0
	beq	@f
*
	lea.l	patch_data_table_map(pc),a0
	bsr	memory_patch		* パッチ実行
@@:
*
* 移動高速化パッチ
*
	move.b	ex_scroll_flag(pc),d0
	beq	@f
*
	lea.l	patch_data_table_scroll(pc),a0
	bsr	memory_patch		* パッチ実行
*
	move.b	ex_scroll_flag(pc),d0
	cmpi.b	#1,d0
	bne	@f
*[全角]ロックする
	bset.b	#6,key_led_new
@@:
*
* 戦闘高速化パッチ
*
	move.b	ex_battle_flag(pc),d0
	beq	@f
*
	lea.l	patch_data_table_battle(pc),a0
	bsr	memory_patch		* パッチ実行
*
	move.b	ex_battle_flag(pc),d0
	cmpi.b	#1,d0
	bne	@f
*[ひらがな]ロックする
	bset.b	#5,key_led_new
@@:
*
* 経験値２倍パッチ
*
	move.b	ex_exp_flag(pc),d0
	beq	@f
*
	lea.l	patch_data_table_exp(pc),a0
	bsr	memory_patch		* パッチアドレス決定
	movea.l	last_patch_address(pc),a0
	move.l	2(a0),exp_address	* 経験値を保存するアドレスを保存
	move.w	#JSR_code,(a0)+
	move.l	#exp_patch,(a0)
@@:
*
* ほぼ最強装備パッチ
*
	move.b	ex_super_flag(pc),d0
	beq	@f
*
	lea.l	patch_data_table_super(pc),a0
	bsr	memory_patch		* パッチ実行
@@:
*
* ずうパッチ
*
	move.b	ex_zoo_flag(pc),d0
	beq	@f
*
	lea.l	patch_data_table_zoo(pc),a0
	bsr	memory_patch		* パッチ実行
@@:
* パッチ結果を表示後の、キー入力待ち（/Zスイッチ時のみ）
	bsr	patch_print_wait

**********************************************************************
* USERDATAディレクトリ（セーブデータ領域）がなければ作る
**********************************************************************
	lea.l	emedra_all_path(pc),a0
	lea.l	set_path_buf(pc),a1	* パス名を登録するバッファ
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*
	subq.w	#1,a1
	lea.l	userdata_path(pc),a0
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*
	move.w	#$0010,-(sp)		* 検索するアトリビュートは、ディレクトリ
	pea.l	set_path_buf(pc)
	pea.l	files_buffer(pc)
	DOS	_FILES			* $ff4e
	lea.l	10(sp),sp
*
	cmpi.l	#-2,d0
	bne	@f
*USERDATAディレクトリを作成
	pea.l	set_path_buf(pc)
	DOS	_MKDIR			* $ff39
	addq.w	#4,sp
@@:

**********************************************************************
* プログラム実行
**********************************************************************
*TIMER-Dを使用可能にする
	bsr	tdpause_keep
*キーLEDの設定
	move.b	key_led_new(pc),d1
	IOCS	_KEY_INIT
*実行
	move.l	program_exec_address(pc),-(sp)
	move.w	#$0004,-(sp)		* 実行のみ
	DOS	_EXEC			* $ff4b
	addq.w	#6,sp
	move.l	d0,emedra_exe_exit_code
*キーLED状態を戻す
	move.b	key_led_backup(pc),d1
	IOCS	_KEY_INIT
*TIMER-D設定を復活させる
	bsr	tdpause_free
*カレントディレクトリを戻す
	movea.l	start_a0_backup(pc),a0
	adda.w	#$80,a0			* a0.l=EMEDRA_patch.xの起動パス格納アドレス
	move.l	a0,-(sp)
	DOS	_CHDIR			* $ff3b
	addq.w	#4,sp
*emedra.xの戻り値をチェック
	move.l	emedra_exe_exit_code(pc),d0
	bmi	program_exec_error

**********************************************************************
* 終了処理
**********************************************************************
emedra_exit:
*ミュージックドライバを常駐解除する
	bsr	mdevice_free
*
	DOS	_EXIT


**********************************************************************
* オープニング処理
**********************************************************************
opening_exec:
*カレントドライブの変更
	lea.l	emedra_all_path(pc),a0	* 格納パス
	moveq.l	#0,d0
	move.b	(a0),d0
	andi.b	#$1f,d0
	subq.b	#1,d0			* A=0,B=1…
	move.w	d0,-(sp)
	DOS	_CHGDRV			* $ff0e
	addq.w	#2,sp
	bmi	program_load_error	* カレント移動エラー
*パスの変更
	lea.l	exe_load_path(pc),a1	* ファイル名作成領域
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*
	subq.w	#1,a1
	lea.l	bin_path(pc),a0		* 'BIN\'
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*
	pea.l	exe_load_path(pc)
	DOS	_CHDIR			* $ff3b
	addq.w	#4,sp
	bmi	program_load_error	* カレント移動エラー

*読み込み
	clr.l	-(sp)			* 環境は親と同じ
	pea.l	emopen_command_line(pc)	* コマンドライン
	pea.l	emopen_exe_name(pc)	* ファイル名
	move.w	#$0001,-(sp)		* ロードのみ
	DOS	_EXEC			* $ff4b
	lea.l	14(sp),sp
	tst.l	d0
	bmi	program_load_error	* 読み込みエラー
	bsr	exec_extract		* LZX圧縮チェック＆解凍
	lea.l	$100(a0),a0
	move.l	a0,program_top_address		* 先頭アドレスを保存
	move.l	a4,program_exec_address		* 実行アドレスを保存

*パッチ
	lea.l	patch_data_table_opening(pc),a0
	bsr	memory_patch		* パッチ実行
*パッチ結果を表示後の、キー入力待ち（/Zスイッチ時のみ）
	bsr	patch_print_wait

*TIMER-Dを使用可能にする
	bsr	tdpause_keep
*実行
	move.l	program_exec_address(pc),-(sp)
	move.w	#$0004,-(sp)		* 実行のみ
	DOS	_EXEC			* $ff4b
	addq.w	#6,sp
**	move.l	d0,emedra_exe_exit_code
*emedra.xの戻り値をチェック
**	move.l	emedra_exe_exit_code(pc),d0
	tst.l	d0
	bmi	program_exec_error

*TIMER-D設定を復活させる
	bsr	tdpause_free
*
	bra	emedra_exit


**********************************************************************
* ミュージックモード処理
**********************************************************************
music_mode_exec:
*カレントドライブの変更
	lea.l	emedra_all_path(pc),a0	* 格納パス
	moveq.l	#0,d0
	move.b	(a0),d0
	andi.b	#$1f,d0
	subq.b	#1,d0			* A=0,B=1…
	move.w	d0,-(sp)
	DOS	_CHGDRV			* $ff0e
	addq.w	#2,sp
	bmi	program_load_error	* カレント移動エラー
*パスの変更
	lea.l	exe_load_path(pc),a1	* ファイル名作成領域
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*
	subq.w	#1,a1
	lea.l	bin_path(pc),a0		* 'BIN\'
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*
	pea.l	exe_load_path(pc)
	DOS	_CHDIR			* $ff3b
	addq.w	#4,sp
	bmi	program_load_error	* カレント移動エラー

*読み込み
	clr.l	-(sp)			* 環境は親と同じ
	pea.l	mode_command_line(pc)	* コマンドライン
	pea.l	mode_exe_name(pc)	* ファイル名
	move.w	#$0001,-(sp)		* ロードのみ
	DOS	_EXEC			* $ff4b
	lea.l	14(sp),sp
	tst.l	d0
	bmi	program_load_error	* 読み込みエラー
	bsr	exec_extract		* LZX圧縮チェック＆解凍
	lea.l	$100(a0),a0
	move.l	a0,program_top_address		* 先頭アドレスを保存
	move.l	a4,program_exec_address		* 実行アドレスを保存

*パッチ
	lea.l	patch_data_table_music_mode(pc),a0
	bsr	memory_patch		* パッチ実行
*パッチ結果を表示後の、キー入力待ち（/Zスイッチ時のみ）
	bsr	patch_print_wait

*TIMER-Dを使用可能にする
	bsr	tdpause_keep
*実行
	move.l	program_exec_address(pc),-(sp)
	move.w	#$0004,-(sp)		* 実行のみ
	DOS	_EXEC			* $ff4b
	addq.w	#6,sp
**	move.l	d0,emedra_exe_exit_code
*emedra.xの戻り値をチェック
**	move.l	emedra_exe_exit_code(pc),d0
	tst.l	d0
	bmi	program_exec_error

*TIMER-D設定を復活させる
	bsr	tdpause_free
*
	bra	emedra_exit


**********************************************************************
* タイトル表示
**********************************************************************
ifdef	DEBUG

title_print:
	movem.l	d1-d7/a0-a6,-(sp)
*カレントドライブの変更
	lea.l	emedra_all_path(pc),a0	* 格納パス
	moveq.l	#0,d0
	move.b	(a0),d0
	andi.b	#$1f,d0
	subq.b	#1,d0			* A=0,B=1…
	move.w	d0,-(sp)
	DOS	_CHGDRV			* $ff0e
	addq.w	#2,sp
	bmi	title_print_error_exit	* カレント移動エラー
*パスの変更
	lea.l	exe_load_path(pc),a1	* ファイル名作成領域
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*
	subq.w	#1,a1
	lea.l	bin_path(pc),a0		* 'BIN\'
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*
	pea.l	exe_load_path(pc)
	DOS	_CHDIR			* $ff3b
	addq.w	#4,sp
	bmi	title_print_error_exit	* カレント移動エラー

*読み込み
	clr.l	-(sp)			* 環境は親と同じ
	pea.l	emopen_command_line(pc)	* コマンドライン
	pea.l	emopen_exe_name(pc)	* ファイル名
	move.w	#$0001,-(sp)		* ロードのみ
	DOS	_EXEC			* $ff4b
	lea.l	14(sp),sp
	tst.l	d0
	bmi	title_print_error_exit	* 読み込みエラー
	bsr	exec_extract		* LZX圧縮チェック＆解凍
	lea.l	$100(a0),a0
	move.l	a0,program_top_address		* 先頭アドレスを保存
	move.l	a4,program_exec_address		* 実行アドレスを保存

*パッチ
	lea.l	patch_data_table_opening(pc),a0
	bsr	memory_patch		* パッチ実行
	lea.l	patch_data_table_title_print(pc),a0
	bsr	memory_patch		* パッチ実行
*パッチ結果を表示後の、キー入力待ち（/Zスイッチ時のみ）
	bsr	patch_print_wait

*TIMER-Dを使用可能にする
	bsr	tdpause_keep
*実行
	move.w	#$c,d1
	IOCS	_CRTMOD
	clr.l	-(sp)
	DOS	_SUPER
	addq.w	#4,sp
	move.l	d0,-(sp)		* SSP保存
*
	movea.l	last_patch_address(pc),a0
	move.l	#$4fef000c,30(a0)	* (lea.l 12(sp),sp)
	move.w	#RTS_code,34(a0)
	subq.w	#4,a0			* サブルーチンの先頭アドレス
	jsr	(a0)
*
	DOS	_SUPER
	addq.w	#4,sp

*TIMER-D設定を復活させる
	bsr	tdpause_free
*ダミーEXEC
	bsr	dummy_exec
*
	movem.l	(sp)+,d1-d7/a0-a6
	moveq.l	#0,d0
	rts

title_print_error_exit:
	movem.l	(sp)+,d1-d7/a0-a6
	moveq.l	#-1,d0
	rts

endif

ifdef	DEBUG

**title_print:
	movem.l	d1-d7/a0-a6,-(sp)
*カレントドライブの変更
	lea.l	emedra_all_path(pc),a0	* 格納パス
	moveq.l	#0,d0
	move.b	(a0),d0
	andi.b	#$1f,d0
	subq.b	#1,d0			* A=0,B=1…
	move.w	d0,-(sp)
	DOS	_CHGDRV			* $ff0e
	addq.w	#2,sp
	bmi	title_print_error_exit	* カレント移動エラー
*パスの変更
	lea.l	exe_load_path(pc),a1	* ファイル名作成領域
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*
	subq.w	#1,a1
	lea.l	bin_path(pc),a0		* 'BIN\'
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*
	pea.l	exe_load_path(pc)
	DOS	_CHDIR			* $ff3b
	addq.w	#4,sp
	bmi	title_print_error_exit	* カレント移動エラー

*読み込み
	clr.l	-(sp)			* 環境は親と同じ
	pea.l	mode_command_line(pc)	* コマンドライン
	pea.l	mode_exe_name(pc)	* ファイル名
	move.w	#$0001,-(sp)		* ロードのみ
	DOS	_EXEC			* $ff4b
	lea.l	14(sp),sp
	tst.l	d0
	bmi	title_print_error_exit	* 読み込みエラー
	bsr	exec_extract		* LZX圧縮チェック＆解凍
	lea.l	$100(a0),a0
	move.l	a0,program_top_address		* 先頭アドレスを保存
	move.l	a4,program_exec_address		* 実行アドレスを保存

*パッチ
	lea.l	patch_data_table_music_mode(pc),a0
	bsr	memory_patch		* パッチ実行
	lea.l	patch_data_table_title_print(pc),a0
	bsr	memory_patch		* パッチ実行
*パッチ結果を表示後の、キー入力待ち（/Zスイッチ時のみ）
	bsr	patch_print_wait

*TIMER-Dを使用可能にする
	bsr	tdpause_keep
*実行
	move.w	#$c,d1
	IOCS	_CRTMOD
	clr.l	-(sp)
	DOS	_SUPER
	addq.w	#4,sp
	move.l	d0,-(sp)		* SSP保存
*
	movea.l	last_patch_address(pc),a0
	subq.w	#8,a0			* サブルーチンの先頭アドレス
	jsr	(a0)
*
	DOS	_SUPER
	addq.w	#4,sp

*TIMER-D設定を復活させる
	bsr	tdpause_free
*ダミーEXEC
	bsr	dummy_exec
*
	movem.l	(sp)+,d1-d7/a0-a6
	moveq.l	#0,d0
	rts

**title_print_error_exit:
	movem.l	(sp)+,d1-d7/a0-a6
	moveq.l	#-1,d0
	rts

endif

**********************************************************************
* スイッチ解析
*
*　入力：a2.l=解析する文字列の先頭アドレス
*　出力：なし
**********************************************************************
switch_check:
switch_check_loop:
	move.b	(a2)+,d0
	beq	switch_check_exit
	cmpi.b	#' ',d0
	beq	switch_check_loop
	cmpi.b	#7,d0			* TAB
	beq	switch_check_loop
	cmpi.b	#'-',d0
	beq	@f
	cmpi.b	#'/',d0
	beq	@f
	cmpi.b	#'?',d0
	beq	manual
	subq.w	#1,a2
	bra	emedra_path_set
@@:
	move.b	(a2)+,d0
	cmpi.b	#'?',d0
	beq	manual
	and.b	#$df,d0			* 大文字化
	cmpi.b	#'G',d0
	beq	g_switch
	cmpi.b	#'M',d0
	beq	m_switch
	cmpi.b	#'O',d0
	beq	o_switch
	cmpi.b	#'Z',d0
	beq	z_switch
	cmpi.b	#'H',d0
	beq	manual
	bra	manual

*Ｇスイッチ指定時（ゲーム）
g_switch:
	st.b	game_switch_flag
	bra	switch_check_loop

*Ｍスイッチ指定時（ミュージックモード）
m_switch:
	st.b	music_mode_switch_flag
	bra	switch_check_loop

*Ｏスイッチ指定時（オープニング）
o_switch:
	st.b	opening_switch_flag
	bra	switch_check_loop

*Ｚスイッチ指定時
z_switch:
	st.b	zoo_switch_flag
	bra	switch_check_loop

switch_check_exit:
	rts


*パス名読み込み
emedra_path_set:
	lea.l	emedra_all_path(pc),a0
	moveq.l	#0,d1			* パス名の長さ
@@:
	move.b	(a2),d0			* (a2)+ にすると、0チェックでバグる(^^;
	beq	@f
	cmpi.b	#' ',d0
	beq	@f
	cmpi.b	#7,d0
	beq	@f
	addq.w	#1,a2
	addq.b	#1,d1
	move.b	d0,(a0)+
	bra	@b
@@:
*'\'が省略されていたら付ける
	cmpi.b	#2,d1
	bls	@f			* 2>=d1
	cmpi.b	#'\',-1(a0)
	beq	1f
@@:
	move.b	#'\',(a0)+
1:
	clr.b	(a0)
ifdef	DEBUG
	pea.l	emedra_path_mes(pc)
	DOS	_PRINT
	addq.w	#4,sp
	pea.l	emedra_all_path(pc)
	DOS	_PRINT
	addq.w	#4,sp
	pea.l	cr_mes(pc)
	DOS	_PRINT
	addq.w	#4,sp
	bra	@f
emedra_path_mes:
	.dc.b	'パス名：',0
	.even
@@:
endif
	st.b	emedra_path_set_flag
	rts

**********************************************************************
* メモリパッチ
*
*　入力：a0.l=パッチテーブルのアドレス
*　出力：なし
**********************************************************************
memory_patch:
	movem.l	d0-d7/a0-a6,-(sp)
1:
	move.w	(a0)+,d0
	beq	memory_patch_exit	* 全パッチ終了
*
	lea.l	memory_patch(pc),a1	* disしたらパニックになると思う算出方法(^^;
	adda.w	d0,a1
	movea.l	(a1)+,a4		* a4.l=検索基準アドレス
	move.w	(a1)+,d1		* d1.w=チェックデータ長（ワード単位）
	movea.l	a1,a2			* a1.l=チェック元データアドレス
	adda.w	d1,a2
	adda.w	d1,a2			* a2.l=書き換え後データアドレス
	adda.l	program_top_address(pc),a4
	movea.l	a4,a5
	suba.w	#$100,a4		* 検索開始アドレス
	adda.w	#$100,a5		* 検索終了アドレス
*
	tst.b	zoo_switch_flag
	beq	@f
*変更内容を表示する（要Ｚスイッチ）
	movem.l	d0/a2,-(sp)
	adda.w	d1,a2
	adda.w	d1,a2			* 変更内容メッセージポインタ
	move.l	a2,-(sp)
	DOS	_PRINT
	pea.l	cr_mes(pc)
	DOS	_PRINT
	addq.w	#8,sp
	movem.l	(sp)+,d0/a2
@@:
2:
	movea.l	a1,a3			* チェックデータアドレス設定
	move.w	(a3)+,d0
*１ワード目一致チェックループ
@@:
	cmp.w	(a4)+,d0
	beq	@f
	cmp.w	(a4)+,d0
	beq	@f
	cmp.w	(a4)+,d0
	beq	@f
	cmp.w	(a4)+,d0
	beq	@f
	cmpa.l	a5,a4			* 高速化のため、エンドチェックは８バイトに１回
	bcs	@b
*
	bra	5f			* プログラムの終端に達した
@@:
*１ワード目一致
	move.l	a4,d7			* a4保存
	cmpi.w	#1,d1
	beq	4f			* １ワードデータなので見つかり
	move.w	d1,d2
	subq.w	#2,d2
@@:
	cmpm.w	(a3)+,(a4)+
	bne	3f
	dbra	d2,@b
	bra	4f			* 見つかった
3:
*２ワード目以降で不一致
	move.l	d7,a4			* a4復帰
	cmpa.l	a5,a4
	bcs	2b			* 検索続行
	bra	5f			* 見つからなかった

*見つかった
4:
	movem.l	a0-a1,-(sp)
	move.l	d7,a1
	suba.w	#2,a1			* 書き換えアドレス
	movea.l	a2,a0
	move.w	d1,d2
	subq.w	#1,d2
*書き換えループ
@@:
	move.w	(a0)+,(a1)+
	dbra	d2,@b
	move.l	a1,last_patch_address	* 最後に書き換えた場所＋１を保存しておく
	movem.l	(sp)+,a0-a1
*書き換えアドレス表示（要Ｚスイッチ）
	tst.b	zoo_switch_flag
	beq	@f
	movem.l	d0/a0-a1,-(sp)
	pea.l	hexheader_mes(pc)
	DOS	_PRINT
	addq.w	#4,sp
	move.l	program_top_address(pc),a0	* 検索開始アドレス
	move.l	d7,a1
	suba.w	#2,a1			* 書き換えアドレス
	suba.l	a0,a1			* オフセット
	move.l	a1,d0
	bsr	lhex_print
	movem.l	(sp)+,d0/a0-a1
@@:
	bra	3b

*見つらなかった（１データ検索終了）
5:
	tst.b	zoo_switch_flag
	beq	@f
	move.l	d0,-(sp)
	pea.l	cr_mes(pc)
	DOS	_PRINT
	addq.w	#4,sp
	move.l	(sp)+,d0
@@:
	bra	1b			* 次のデータ検索へ

memory_patch_exit:
	movem.l	(sp)+,d0-d7/a0-a6
	rts

**********************************************************************
* ダミーＥＸＥＣ
*　・プログラムをロードして実行しないままEXITしようとすると、ロードし
*　　た所から再実行されてしまうので、ダミーでEXECしてやる。
*
*　入力：なし
*　出力：なし
**********************************************************************
dummy_exec:
	movem.l	d1-d7/a0-a6,-(sp)
	movea.l	program_exec_address(pc),a0
	move.w	#$ff00,(a0)		* DOS _EXEC のコード
	move.l	a0,-(sp)
	move.w	#$0004,-(sp)		* 実行のみ
	DOS	_EXEC			* $ff4b
	addq.w	#6,sp
	movem.l	(sp)+,d1-d7/a0-a6
	rts

**********************************************************************
* １６進数表示
*
*　入力：d0.l=表示するデータ
*　出力：なし
**********************************************************************
lhex_print:
	move.w	d0,-(sp)
	swap.w	d0
	bsr	whex_print
	move.w	(sp)+,d0
whex_print:
	move.w	d0,-(sp)
	lsr.w	#8,d0
	bsr	bhex_print
	move.w	(sp)+,d0
bhex_print:
	move.b	d0,-(sp)
	andi.b	#$f0,d0
	lsr.b	#4,d0
	bsr	hhex_print
	move.b	(sp)+,d0
	andi.b	#$0f,d0
hhex_print:
	addi.b	#'0',d0
	cmpi.b	#'9'+1,d0
	bmi	@f
	addq.b	#7,d0
@@:
	move.w	d0,-(sp)
	DOS	_INPOUT			* 一文字表示
	addq.w	#2,sp
	rts

**********************************************************************
* ＬＺＸ圧縮されていたら解凍する（SF2_patch.s を参考にしています）
*
*　入力：なし
*　出力：なし
**********************************************************************
exec_extract:
	movem.l	d0-d7/a0/a2-a3/a5-a6,-(sp)
	cmpi.l	#'LZX ',$04(a4)
	bne	1f			* lzx v0.30以降の圧縮がされていなかった
	cmpi.w	#$4ed4,-$2e(a1)		* 自己解凍ルーチン内 jmp (a4)存在確認
	bne	1f
	movea.l	a4,a0			* 転送
	move.l	$0e(a0),d0
	add.l	a0,d0			* 実行アドレス算出
	movem.l	d0,-(sp)		* 退避
	move.l	$12(a0),d0
	add.l	a0,d0			* データサイズ算出
	movem.l	d0,-(sp)		* 退避
	move.l	himem_pointer(pc),d6
	move.l	d6,$04(a0)		* メモリ使用上限アドレス設定
	movea.l	a0,a5
	move.l	a0,$08(a0)		* 解凍アドレス設定
	lea.l	@f(pc),a4		* 戻りアドレス設定
	jmp	2(a0)			* lzx自己解凍処理ルーチンへジャンプ
@@:
	movem.l	(sp)+,a1/a4		* データ終端＆実行アドレス復帰
1:
	movem.l	(sp)+,d0-d7/a0/a2-a3/a5-a6
	move.l	a1,$38(a0)		* プロセス初期スタックアドレス強制設定
	rts

**********************************************************************
* コンフィグファイルを読み込み、スイッチを解析する
*
*　入力：なし
*　出力：なし
**********************************************************************
config_file:
	movem.l	d0-d7/a0-a6,-(sp)
*
	movea.l	start_a0_backup(pc),a0
	adda.w	#$80,a0			* a0.l=EMEDRA_patch.xの起動パス格納アドレス
	lea.l	config_file_name(pc),a1
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*
	subq.w	#1,a1
	lea.l	config_name(pc),a0
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*
	clr.l	-(sp)
	pea.l	config_file_name(pc)
	DOS	_OPEN			* $ff3d
	addq.w	#8,sp
	tst.l	d0
	bmi	config_load_error
	move.w	d0,d7			* d7.w=ファイルハンドル
*
	move.w	#2,-(sp)		* ファイル終端へ
	clr.l	-(sp)			* オフセット０
	move.w	d7,-(sp)		* ハンドル
	DOS	_SEEK			* $ff42
	addq.w	#8,sp
	move.l	d0,d6			* d6.l=ファイルサイズ
*
	move.l	d6,-(sp)		* 確保するメモリサイズ
	DOS	_MALLOC			* $ff48
	addq.w	#4,sp
	tst.l	d0
	bmi	config_file_exit	* メモリ確保エラー
	movea.l	d0,a6			* a6.l=確保したアドレス
	movea.l	a6,a5
	adda.l	d6,a5			* a5.l=メモリ終端＋１
*
	clr.w	-(sp)			* ファイル先頭へ
	clr.l	-(sp)			* オフセット０
	move.w	d7,-(sp)		* ハンドル
	DOS	_SEEK			* $ff42
	addq.w	#8,sp
*
	move.l	d6,-(sp)		* 読み込むサイズ
	move.l	a6,-(sp)		* 読み込むアドレス
	move.w	d7,-(sp)		* ハンドル
	DOS	_READ			* $ff3f
	lea.l	10(sp),sp
*
	move.w	d7,-(sp)
	DOS	_CLOSE
	addq.w	#2,sp
*
	movea.l	a6,a0
config_line_loop:
	cmpa.l	a0,a5
	bls	config_file_memfree
	move.b	(a0)+,d0
	cmpi.b	#'*',d0
	beq	next_line
	cmpi.b	#$0d,d0
	beq	next_line
*'EX_'が一致するか
	cmpi.b	#'E',d0
	bne	next_line
	move.b	(a0)+,d0
	cmpi.b	#'X',d0
	bne	next_line
	move.b	(a0)+,d0
	cmpi.b	#'_',d0
	bne	next_line
*
	move.b	(a0)+,d0
	cmpi.b	#'B',d0
	bne	@f
*'EX_BATTLE'だった
	bsr	flagon_check
	move.b	d0,ex_battle_flag
	bra	next_line
@@:
	cmpi.b	#'E',d0
	bne	@f
*'EX_EXP'だった
	bsr	flagon_check
	move.b	d0,ex_exp_flag
	bra	next_line
@@:
	cmpi.b	#'M',d0
	bne	@f
*'EX_MAP'だった
	bsr	flagon_check
	move.b	d0,ex_map_flag
	bra	next_line
@@:
	cmpi.b	#'Z',d0
	bne	@f
*'EX_ZOO'だった
	bsr	flagon_check
	move.b	d0,ex_zoo_flag
	bra	next_line
@@:
	cmpi.b	#'S',d0
	bne	next_line
	move.b	(a0)+,d0
	cmpi.b	#'U',d0
	bne	@f
*'EX_SUPER'だった
	bsr	flagon_check
	move.b	d0,ex_super_flag
	bra	next_line
@@:
	cmpi.b	#'C',d0
	bne	@f
*'EX_SCROLL'だった
	bsr	flagon_check
	move.b	d0,ex_scroll_flag
	bra	next_line
@@:
next_line:
	move.b	(a0)+,d0
	cmpa.l	a0,a5
	bls	config_file_memfree
	cmpi.b	#$0a,d0
	bne	next_line
	bra	config_line_loop

config_file_memfree:
	move.l	a6,-(sp)
	DOS	_MFREE			* $ff49
	addq.w	#4,sp

config_file_exit:
	movem.l	(sp)+,d0-d7/a0-a6
	rts


flagon_check:
	move.b	(a0)+,d0
	cmpa.l	a0,a5
	bls	@f
	cmpi.b	#$0d,d0
	beq	@f
	cmpi.b	#'*',d0
	beq	@f
	cmpi.b	#'1',d0
	bmi	flagon_check
	cmpi.b	#'9',d0
	bhi	flagon_check
*
	subi.b	#'0',d0		* d0.b= 1～9
	rts
@@:
	subq.w	#1,a0
	moveq.l	#0,d0
	rts

**********************************************************************
* TIMER-D を使用可能にする／戻す
*
*　入力：なし
*　出力：なし
**********************************************************************
tdpause_keep:
	pea.l	get_pr_buffer(pc)
	clr.w	-(sp)
	DOS	_GET_PR
	addq.w	#6,sp
	tst.l	d0
	bmi	@f			* スレッドはなかった（BG未使用）
*
	clr.l	-(sp)
	DOS	_SUPER
	addq.w	#4,sp
	move.l	d0,-(sp)		* SSP保存
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	move.l	$0110.w,timerd_vector_backup
	bsr	timerd_stop
	lea.l	iocs6b_vector_backup(pc),a0
	move.l	$05ac.w,(a0)
	lea.l	new_iocs6b(pc),a0
	move.l	a0,$05ac.w
	move.w	(sp)+,sr
	DOS	_SUPER
	addq.w	#4,sp
	st.b	tdpause_flag
@@:
	move.b	zoo_switch_flag(pc),d0	* tst.b
	beq	@f
*
	pea.l	bg_stop_mes(pc)
	DOS	_PRINT
	addq.w	#4,sp
@@:
	rts

tdpause_free:
	move.b	tdpause_flag(pc),d0
	beq	@f
*
	clr.l	-(sp)
	DOS	_SUPER
	addq.w	#4,sp
	move.l	d0,-(sp)		* SSP保存
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	move.l	iocs6b_vector_backup(pc),$05ac.w
	move.l	timerd_vector_backup(pc),$0110.w
	lea.l	$00e88000,a0
	move.b	#$77,$1d(a0)
	move.b	#$14,$25(a0)
	move.b	$09(a0),d0
	ori.b	#$10,d0
	move.b	d0,$09(a0)
	move.b	$15(a0),d0
	ori.b	#$10,d0
	move.b	d0,$15(a0)
	move.w	(sp)+,sr
	DOS	_SUPER
	addq.w	#4,sp
@@:
	rts

* 新しい IOCS _TIMERDST
new_iocs6b:
	movem.l	d1/a0,-(sp)
	move.l	a1,d0
	beq	timerd_stop_2		* 割り込み禁止設定
*
	move.l	$0110.w,d0
	cmpi.l	#$00c00000,d0
	bcs	@f			* すでに設定されている
*
	move.l	a1,$0110.w
	lea.l	$00e88000,a0
	move.w	d1,d0
	ror.w	#8,d0
	andi.w	#$0007,d0
	ori.w	#$0070,d0
	move.b	d0,$1d(a0)
	move.b	d1,$25(a0)
	move.b	$09(a0),d0
	ori.b	#$10,d0
	move.b	d0,$09(a0)
	move.b	$15(a0),d0
	ori.b	#$10,d0
	move.b	d0,$15(a0)
	moveq.l	#0,d0
@@:
	movem.l	(sp)+,d1/a0
	rts

timerd_stop:
	movem.l	d1/a0,-(sp)
timerd_stop_2:
	lea.l	$00e88000,a0
	move.b	#$70,$1d(a0)
	move.b	$09(a0),d0
	andi.b	#$ef,d0
	move.b	d0,$09(a0)
	move.b	$15(a0),d0
	andi.b	#$ef,d0
	move.b	d0,$15(a0)
	lea.l	tdpause_rte(pc),a0
	move.l	a0,d0
	ori.l	#$44000000,d0
	move.l	d0,$0110.w
	moveq.l	#0,d0
	movem.l	(sp)+,d1/a0
	rts

tdpause_rte:
	rte

**********************************************************************
* ミュージックドライバを常駐させる
*
*　入力：なし
*　出力：なし
**********************************************************************
mdevice_keep:
	movem.l	d0-d7/a0-a6,-(sp)
*
	clr.l	-(sp)
	pea.l	emdrive_name(pc)	* 'EMDRIVE'
	DOS	_OPEN			* $ff3d
	addq.w	#8,sp
	tst.l	d0
	bmi	@f			* まだ常駐していない
*既に常駐していたので、何もしない
	move.w	d0,-(sp)
	DOS	_CLOSE
	addq.w	#2,sp
	bra	mdevice_keep_exit

@@:
	lea.l	adddrv_command_line(pc),a6
*パス検索
	lea.l	adddrv_exe_name(pc),a0
	lea.l	adddrv_file_name(pc),a1
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*ダミーのコマンドライン
	moveq.l	#0,d0
	move.b	d0,(a6)
	move.b	d0,1(a6)
*パス検索
	clr.l	-(sp)			* 環境は親と同じ
	move.l	a6,-(sp)		* コマンドライン
	pea.l	adddrv_file_name(pc)	* ファイル名
	move.w	#2,-(sp)		* 検索
	DOS	_EXEC			* $ff4b
	lea.l	14(sp),sp
	tst.l	d0
	bmi	adddrv_load_error	* 読み込みエラー
*コマンドライン作成
	lea.l	emedra_all_path(pc),a0	* 格納パス
	lea.l	1(a6),a1
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*
	subq.w	#1,a1
	lea.l	mdevice_sys_name(pc),a0
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*コマンドラインの長さ
	movea.l	a1,a0
	lea.l	1(a6),a2
	suba.l	a2,a0
	move.l	a0,d0
	move.b	d0,(a6)
*一行改行
	pea.l	cr_mes(pc)
	DOS	_PRINT
	addq.w	#4,sp
*実行（常駐）
	clr.l	-(sp)			* 環境は親と同じ
	move.l	a6,-(sp)		* コマンドライン
	pea.l	adddrv_file_name(pc)	* ファイル名
	clr.w	-(sp)			* ロード＆実行
	DOS	_EXEC			* $ff4b
	lea.l	14(sp),sp
	tst.l	d0
	bmi	adddrv_load_error	* 読み込みエラー
*
*一行改行
	pea.l	cr_mes(pc)
	DOS	_PRINT
	addq.w	#4,sp
*ADDDRVしたフラグをオン
	st.b	adddrv_use_flag
*
mdevice_keep_exit:
	movem.l	(sp)+,d0-d7/a0-a6
	rts

**********************************************************************
* ミュージックドライバを常駐解除する
*
*　入力：なし
*　出力：なし
**********************************************************************
mdevice_free:
	movem.l	d0-d7/a0-a6,-(sp)
*
	move.b	adddrv_use_flag(pc),d0
	beq	mdevice_free_exit	* 常駐していないので、開放しない
*
	lea.l	deldrv_command_line(pc),a6
*パス検索
	lea.l	deldrv_exe_name(pc),a0
	lea.l	deldrv_file_name(pc),a1
@@:
	move.b	(a0)+,(a1)+
	bne	@b
*ダミーのコマンドライン
	moveq.l	#0,d0
	move.b	d0,(a6)
	move.b	d0,1(a6)
*パス検索
	clr.l	-(sp)			* 環境は親と同じ
	move.l	a6,-(sp)		* コマンドライン
	pea.l	deldrv_file_name(pc)	* ファイル名
	move.w	#2,-(sp)		* 検索
	DOS	_EXEC			* $ff4b
	lea.l	14(sp),sp
	tst.l	d0
	bmi	deldrv_load_error	* 読み込みエラー
*実行（常駐解除）
	clr.l	-(sp)			* 環境は親と同じ
	move.l	a6,-(sp)		* コマンドライン
	pea.l	deldrv_file_name(pc)	* ファイル名
	clr.w	-(sp)			* ロード＆実行
	DOS	_EXEC			* $ff4b
	lea.l	14(sp),sp
	tst.l	d0
	bmi	deldrv_load_error	* 読み込みエラー
*
mdevice_free_exit:
	movem.l	(sp)+,d0-d7/a0-a6
	rts

**********************************************************************
* パッチ結果を表示後の、キー入力待ち（/Zスイッチ時のみ）
**********************************************************************
patch_print_wait:
	move.l	d0,-(sp)
	move.b	zoo_switch_flag(pc),d0	* tst.b
	beq	@f
*キー入力を待つ
	pea.l	hit_any_key_mes(pc)
	DOS	_PRINT
	addq.w	#4,sp
	DOS	_INKEY			* $ff07
@@:
	move.l	(sp)+,d0
	rts

**********************************************************************
* 使用方法表示
**********************************************************************
manual:
	pea.l	manual_mes(pc)
	DOS	_PRINT
	addq.w	#4,sp
	bra	error_exit

**********************************************************************
* エラー処理
**********************************************************************
adddrv_load_error:
	pea.l	color2n_mes(pc)		* 黄色にする
	DOS	_PRINT
	addq.w	#4,sp
	pea.l	adddrv_exe_name(pc)
	DOS	_PRINT
	addq.w	#4,sp
	pea.l	adddrv_load_error_mes(pc)
	bra	1f

deldrv_load_error:
	pea.l	color2n_mes(pc)		* 黄色にする
	DOS	_PRINT
	addq.w	#4,sp
	pea.l	deldrv_exe_name(pc)
	DOS	_PRINT
	addq.w	#4,sp
	pea.l	deldrv_load_error_mes(pc)
	bra	1f

config_load_error:
	pea.l	color2n_mes(pc)		* 黄色にする
	DOS	_PRINT
	addq.w	#4,sp
	pea.l	exe_load_path(pc)	* パス名
	DOS	_PRINT
	addq.w	#4,sp
	pea.l	config_name(pc)		* 'emedra.cnf'
	DOS	_PRINT
	addq.w	#4,sp
	pea.l	config_load_error_mes(pc)
	bra	1f

program_load_error:
	pea.l	program_load_error_mes(pc)
	bra	@f

program_exec_error:
	pea.l	program_exec_error_mes(pc)
	bra	@f
@@:
	pea.l	color2n_mes(pc)		* 黄色にする
	DOS	_PRINT
	addq.w	#4,sp
	pea.l	exe_load_path(pc)	* パス名
	DOS	_PRINT
	addq.w	#4,sp
	pea.l	emedra_exe_name(pc)	* 'emedra.x'
	DOS	_PRINT
	addq.w	#4,sp
	bra	1f

setblock_error:
	pea.l	setblock_error_mes(pc)
	bra	@f

patch_error:
	bsr	dummy_exec		* ロードしたプログラムを開放する
	pea.l	patch_error_mes(pc)
	bra	@f
@@:
	pea.l	color2n_mes(pc)		* 黄色にする
	DOS	_PRINT
	addq.w	#4,sp
1:
	DOS	_PRINT			* エラーメッセージ表示
	addq.w	#4,sp
	pea.l	color3n_mes(pc)		* 白に戻す
	DOS	_PRINT
	pea.l	hit_any_key_mes(pc)
	DOS	_PRINT
	addq.w	#8,sp
	DOS	_INKEY			* $ff07
error_exit:
*ミュージックドライバを常駐解除する
	bsr	mdevice_free
*
	move.w	#$0001,-(sp)
	DOS	_EXIT2			* $ff4c


	.data
	.even

*＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠
*＠
*＠ ・パッチデータテーブル
*＠
*＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠

**********************************************************************
* 必ず当てるパッチ達
**********************************************************************
patch_data_table_default:
	.dc.w	patch_data_data_check_off-memory_patch
	.dc.w	patch_data_led-memory_patch
	.dc.w	0			* 終端コード

* キャラクター改造チェックを無効にするパッチ
patch_data_data_check_off:
	.dc.l	$00e554			* アドレス
	.dc.w	3			* ワード数

	.dc.w	$b0ae,$fff8		** 	cmp.l	-$0008(a6),d0
	.dc.w	$6706			**	beq	L00e55c

	.dc.w	$b0ae,$fff8		** 	cmp.l	-$0008(a6),d0
	.dc.w	$6006			**	bra	L00e55c

	.dc.b	'キャラクター改造チェック外し',0
	.even

* 特定ＬＥＤ変更禁止パッチ
patch_data_led:
	.dc.l	$002cb8			* アドレス
	.dc.w	7			* ワード数

	.dc.w	$222f,$0004		**	move.l	$0004(a7),d1
	.dc.w	$242f,$0008		**	move.l	$0008(a7),d2
	.dc.w	$700d,$4e4f		**	IOCS	_LEDMOD
	.dc.w	$4e75			**	rts

	.dc.w	$222f,$0004		**	move.l	$0004(a7),d1
	.dc.w	$242f,$0008		**	move.l	$0008(a7),d2
	.dc.w	$4ef9			**	jmp	[led_patch]
	.dc.l	led_patch		**

	.dc.b	'[ひらがな][全角]キーのLED変更禁止',0
	.even

**********************************************************************
* 戦闘高速化パッチ
**********************************************************************
patch_data_table_battle:
	.dc.w	patch_data_battle-memory_patch
	.dc.w	0			* 終端コード

patch_data_battle:
	.dc.l	$000098			* アドレス
	.dc.w	10			* ワード数

	.dc.w	$202e,$0018		**	move.l	$0018(a6),d0
	.dc.w	$6704			**	beq	L0000a2
	.dc.w	$53ae,$0018		**	subq.l	#1,$0018(a6)
	.dc.w	$202e,$001c		**	move.l	$001c(a6),d0
	.dc.w	$6704			**	beq	L0000ac
	.dc.w	$53ae,$001c		**	subq.l	#1,$001c(a6)

	.dc.w	$4eb9			**	jsr	[battle_patch]
	.dc.l	battle_patch		**	
	.dc.w	$600c			**	bra	L0000ac
	.dc.w	$4e71			**	nop
	.dc.w	$4e71,$4e71		**	nop * 2
	.dc.w	$4e71			**	nop
	.dc.w	$4e71,$4e71		**	nop * 2

	.dc.b	'戦闘高速化',0
	.even

**********************************************************************
* スクロール高速化パッチ
**********************************************************************
patch_data_table_scroll:
	.dc.w	patch_data_scroll-memory_patch
	.dc.w	0			* 終端コード

patch_data_scroll:
	.dc.l	$008c14			* アドレス
	.dc.w	7			* ワード数

	.dc.w	$122f,$000b		**	move.b	$000b(a7),d1
	.dc.w	$e149			**	lsl.w	#8,d1
	.dc.w	$122f,$000f		**	move.b	$000f(a7),d1
	.dc.w	$706b,$4e4f		**	IOCS	_TIMERDST

	.dc.w	$122f,$000f		**	move.b	$000f(a7),d1
	.dc.w	$4eb9			**	jsr	[scroll_patch]
	.dc.l	scroll_patch		**	
	.dc.w	$706b,$4e4f		**	IOCS	_TIMERDST

	.dc.b	'移動高速化',0
	.even

**********************************************************************
* ほぼ最強装備パッチ
**********************************************************************
patch_data_table_super:
	.dc.w	patch_data_super-memory_patch
	.dc.w	0			* 終端コード

patch_data_super:
	.dc.l	$021b70			* アドレス
	.dc.w	$22			* ワード数

	.dc.b	$01,$00,$00,$02,$00,$19,$00,$0a,$00,$3c,$00,$05,$00,$0c,$01,$01
	.dc.b	$01,$01,$00,$00,$01,$29,$3d,$00,$00,$00,$ae,$d4,$f7,$c3,$ef,$ff
	.dc.b	$00,$00					** ここまで、アトルシャン
	.dc.b	$02,$00,$00,$05,$00,$08,$00,$06,$00,$28,$00,$02,$00,$08,$01,$01
	.dc.b	$01,$01,$00,$01,$15,$34,$00,$00,$00,$01,$cb,$ec,$f6,$ff,$00,$00
	.dc.b	$00,$00					** ここまで、タムリン

	.dc.b	$01,$00,$00,$02,$00,$19,$00,$0a,$00,$3c,$00,$05,$00,$0c,$01,$01
	.dc.b	$01,$01,$00,$00,$09,$32,$44,$55,$00,$00,$ae,$d4,$f7,$c3,$ef,$ff
	.dc.b	$00,$00	**	^^^^^^^^^^^^^^^ 武器，鎧，盾，メット
	.dc.b	$02,$00,$00,$05,$00,$08,$00,$06,$00,$28,$00,$02,$00,$08,$01,$01
	.dc.b	$01,$01,$00,$01,$1f,$33,$45,$56,$00,$01,$cb,$ec,$f6,$ff,$00,$00
	.dc.b	$00,$00	**	^^^^^^^^^^^^^^^

	.dc.b	'ほぼ最強装備',0
	.even

**********************************************************************
* どこでもマップパッチ
**********************************************************************
patch_data_table_map:
	.dc.w	patch_data_map-memory_patch
	.dc.w	0			* 終端コード

patch_data_map:
	.dc.l	$0075dc			* アドレス
	.dc.w	3			* ワード数

	.dc.w	$4e90			**	jsr	(a0)
	.dc.w	$4a80			**	tst.l	d0
	.dc.w	$670c			**	beq	L0075ee

	.dc.w	$4e90			**	jsr	(a0)
	.dc.w	$4a80			**	tst.l	d0
	.dc.w	$4e71			**	nop

	.dc.b	'どこでもマップを表示',0
	.even

**********************************************************************
* 経験値２倍パッチ（探すだけ）
**********************************************************************
patch_data_table_exp:
	.dc.w	patch_data_exp-memory_patch
	.dc.w	0			* 終端コード

patch_data_exp:
	.dc.l	$00dc80			* アドレス
	.dc.w	4			* ワード数

	.dc.w	$4e56,$fffc		**	link.w	a6,#-4
	.dc.w	$202e,$0008		**	move.l	$0008(a6),d0

	.dc.w	$4e56,$fffc		**	link.w	a6,#-4
	.dc.w	$202e,$0008		**	move.l	$0008(a6),d0

	.dc.b	'経験値２倍',0
	.even


**********************************************************************
* パス名定義（探すだけ）
**********************************************************************
patch_data_table_path_1:
	.dc.w	patch_data_path_1-memory_patch
	.dc.w	0			* 終端コード

patch_data_path_1:
	.dc.l	$000c98			* アドレス
	.dc.w	9			* ワード数

	.dc.w	$0c10,$0009		**	cmpi.b	#$09,(a0)
	.dc.w	$67ec			**	beq	L000c8a
	.dc.w	$2008			**	move.l	a0,d0
	.dc.w	$4e75			**	rts
	.dc.w	$48e7,$0018		**	movem.l	a3-a4,-(a7)
	.dc.w	$286f,$000c		**	movea.l	$000c(a7),a4

	.dc.w	$0c10,$0009		**	cmpi.b	#$09,(a0)
	.dc.w	$67ec			**	beq	L000c8a
	.dc.w	$2008			**	move.l	a0,d0
	.dc.w	$4e75			**	rts
	.dc.w	$48e7,$0018		**	movem.l	a3-a4,-(a7)
	.dc.w	$286f,$000c		**	movea.l	$000c(a7),a4

	.dc.b	'パス名登録サブ',0
	.even

**********************************************************************
* パス名定義（探すだけ）
**********************************************************************
patch_data_table_path_2:
	.dc.w	patch_data_path_2-memory_patch
	.dc.w	0			* 終端コード

patch_data_path_2:
	.dc.l	$000d2e			* アドレス
	.dc.w	4			* ワード数

	.dc.w	$42a7			**	clr.l	-(a7)
	.dc.w	$487a,$ffc2		**	pea.l	emedra_sys_name(pc)
	.dc.w	$4eb9			**	jsr	open

	.dc.w	$42a7			**	clr.l	-(a7)
	.dc.w	$487a,$ffc2		**	pea.l	emedra_sys_name(pc)
	.dc.w	$4eb9			**	jsr	open

	.dc.b	'パス名登録メイン',0
	.even

**********************************************************************
* ディスクチェック外し（隠し：でも、プロテクトは外さないんだな）
**********************************************************************
patch_data_table_zoo:
	.dc.w	patch_data_zoo_1-memory_patch
	.dc.w	patch_data_zoo_2-memory_patch
	.dc.w	0			* 終端コード

*このパッチは、_B_READ,_B_READDI のふたつ共用
patch_data_zoo_1:
	.dc.l	$008c3c			* アドレス
	.dc.w	5			* ワード数

	.dc.w	$48e7,$1000		**	movem.l	d3,-(a7)
	.dc.w	$4cef,$020e,$0008	**	movem.l	$0008(a7),d1-d3/a1

	.dc.w	$4e75,$4e71		**	rts, nop
	.dc.w	$4e71,$4e71,$4e71	**	nop * 3

	.dc.b	'ずう１',0
	.even

patch_data_zoo_2:
	.dc.l	$009736			* アドレス
	.dc.w	5			* ワード数

	.dc.w	$4e56,$0000		**	link.w	a6,#0
	.dc.w	$3f2e,$000a		**	move.w	$000a(a6),-(a7)
	.dc.w	$ff0f			**	DOS	_DRVCTRL

	.dc.w	$7042			**	moveq.l	#$42,d0
	.dc.w	$4e75			**	rts
	.dc.w	$4e71,$4e71,$4e71	**	nop * 3

	.dc.b	'ずう２',0
	.even

**********************************************************************
* オープニング用パッチ
**********************************************************************
patch_data_table_opening:
	.dc.w	patch_data_opening_open-memory_patch
	.dc.w	patch_data_opening_drvctrl-memory_patch
	.dc.w	0			* 終端コード

* オープニングファイル読み込みパス相対化
patch_data_opening_open:
	.dc.l	$002dc4			* アドレス
	.dc.w	6			* ワード数

	.dc.w	$3f2e,$000e		**	move.w	$000e(a6),-(a7)
	.dc.w	$2f2e,$0008		**	move.l	$0008(a6),-(a7)
	.dc.w	$ff3d			**	DOS	_OPEN
	.dc.w	$5c8f			**	addq.l	#6,a7

	.dc.w	$4ef9			**	jmp	[opening_open_patch]
	.dc.l	opening_open_patch	**	
	.dc.w	$4e71,$4e71,$4e71	**	nop * 3

	.dc.b	'オープニング：パス相対化',0
	.even

* オープニングフロッピーチェック解除
patch_data_opening_drvctrl:
	.dc.l	$002e54			* アドレス
	.dc.w	3			* ワード数

	.dc.w	$3f00			**	move.w	d0,-(a7)
	.dc.w	$ff0f			**	DOS	_DRVCTRL
	.dc.w	$548f			**	addq.l	#2,a7

	.dc.w	$3f00			**	move.w	d0,-(a7)
	.dc.w	$7042			**	moveq.l	#$42,d0
	.dc.w	$548f			**	addq.l	#2,a7

	.dc.b	'オープニング：フロッピーチェック解除',0
	.even

ifdef	DEBUG
* オープニングタイトル表示（v0.99 現在、このパッチは無効）
patch_data_table_title_print:
	.dc.w	patch_data_opening_title_print-memory_patch
	.dc.w	0			* 終端コード

patch_data_opening_title_print:
	.dc.l	$001000			* アドレス
	.dc.w	4			* ワード数

	.dc.w	$4e93			**	jsr	(a3)
	.dc.w	$4e95			**	jsr	(a5)
	.dc.w	$487a,$fe86		**	pea.l	optitle_mbt_name(pc)

	.dc.w	$4e93			**	jsr	(a3)
	.dc.w	$4e95			**	jsr	(a5)
	.dc.w	$487a,$fe86		**	pea.l	optitle_mbt_name(pc)

	.dc.b	'オープニング：タイトル表示用',0
	.even
endif

**********************************************************************
* ミュージックモード用パッチ
**********************************************************************
patch_data_table_music_mode:
	.dc.w	patch_data_music_mode_open-memory_patch
	.dc.w	patch_data_music_mode_drvctrl-memory_patch
	.dc.w	0			* 終端コード

* ミュージックモードファイル読み込みパス相対化
patch_data_music_mode_open:
	.dc.l	$001652			* アドレス
	.dc.w	6			* ワード数

	.dc.w	$3f2e,$000e		**	move.w	$000e(a6),-(a7)
	.dc.w	$2f2e,$0008		**	move.l	$0008(a6),-(a7)
	.dc.w	$ff3d			**	DOS	_OPEN
	.dc.w	$5c8f			**	addq.l	#6,a7

	.dc.w	$4ef9			**	jmp	[music_mode_open_patch]
	.dc.l	music_mode_open_patch	**	
	.dc.w	$4e71,$4e71,$4e71	**	nop * 3

	.dc.b	'ミュージックモード：パス相対化',0
	.even

* ミュージックモードフロッピーチェック解除
patch_data_music_mode_drvctrl:
	.dc.l	$0016e4			* アドレス
	.dc.w	3			* ワード数

	.dc.w	$3f00			**	move.w	d0,-(a7)
	.dc.w	$ff0f			**	DOS	_DRVCTRL
	.dc.w	$548f			**	addq.l	#2,a7

	.dc.w	$3f00			**	move.w	d0,-(a7)
	.dc.w	$7042			**	moveq.l	#$42,d0
	.dc.w	$548f			**	addq.l	#2,a7

	.dc.b	'ミュージックモード：フロッピーチェック解除',0
	.even

ifdef	DEBUG
* オープニングタイトル表示（v0.99 現在、このパッチは無効）
patch_data_table_title_print_1:
	.dc.w	patch_data_music_mode_title_print-memory_patch
	.dc.w	0			* 終端コード

patch_data_music_mode_title_print:
	.dc.l	$00084a			* アドレス
	.dc.w	4			* ワード数

	.dc.w	$48e7,$0018		**	movem.l	a3-a4,-(a7)
	.dc.w	$42a7			**	clr.l	-(a7)
	.dc.w	$47f9			**	lea.l

	.dc.w	$48e7,$0018		**	movem.l	a3-a4,-(a7)
	.dc.w	$42a7			**	clr.l	-(a7)
	.dc.w	$47f9			**	lea.l

	.dc.b	'ミュージックモード：タイトル表示用',0
	.even
endif


*＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠
*＠
*＠ ・各種データ／ワーク
*＠
*＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠＠

**********************************************************************
* メッセージデータ
**********************************************************************
title_mes:
	.dc.b	$1b,'[37m'
	.dc.b	'《エメラルド・ドラゴン　パッチ》'
	.dc.b	$1b,'[0m',13,10
	.dc.b	' EMEDRA_patch.x  version 0.99  (C)1996 ずうやん',13,10,0

manual_mes:
	.dc.b  13,10
	.dc.b  ' 機　能 ：エメラルド・ドラゴンに、パッチを当てます。',13,10
	.dc.b  13,10
	.dc.b  '使用方法：EMEDRA_patch <スイッチ>',13,10
	.dc.b  13,10
	.dc.b  'スイッチ：-G ゲーム起動',13,10
	.dc.b  '          -M ミュージックモード起動',13,10
	.dc.b  '          -O オープニング起動',13,10
	.dc.b  13,10
	.dc.b  0

setblock_error_mes:
	.dc.b	'メモリブロックの確保／解除に失敗しました。',13,10,0

program_load_error_mes:
	.dc.b	' を読み込むことが出来ませんでした。。',13,10
	.dc.b	'指定したパス名を確認して下さい。',13,10,0

patch_error_mes:
	.dc.b	'パッチに失敗しました。',13,10,0

program_exec_error_mes:
	.dc.b	' の実行で、エラーが発生しました。',13,10,0

config_load_error_mes:
	.dc.b	' を読み込むことが出来ませんでした。',13,10
	.dc.b	'EMEDRA_patch.x と同じディレクトリに用意して下さい。',13,10,0

adddrv_load_error_mes:
	.dc.b	' が見つからないので、ミュージックドライバを'
	.dc.b				'常駐させることが出来ません。',13,10,0

deldrv_load_error_mes:
	.dc.b	' が見つからないので、ミュージックドライバを'
	.dc.b				'常駐解除することが出来ません。',13,10,0

bg_stop_mes:
	.dc.b	'バックグラウンドを停止し、TIMER-Dを使用可能にします。',13,10,0

hit_any_key_mes:
	.dc.b	13,10,'何かキーを押して下さい。',13,10,0

*16進数を表示する時の先頭に付ける文字列
hexheader_mes:
	.dc.b	' $',0

*改行する文字列
cr_mes:
	.dc.b	13,10,0

*水色にする
color1n_mes:
	.dc.b	$1b,'[31m',0

*黄色にする
color2n_mes:
	.dc.b	$1b,'[32m',0

*白にする
color3n_mes:
	.dc.b	$1b,'[33m',0

*ゲームプログラムのファイル名
emedra_exe_name:
	.dc.b	'EMEDRA.X',0

*オープニングプログラムのファイル名
emopen_exe_name:
	.dc.b	'EMOPEN.X',0

*ミュージックモードプログラムのファイル名
mode_exe_name:
	.dc.b	'MODE.X',0

adddrv_exe_name:
	.dc.b	'ADDDRV.X',0

deldrv_exe_name:
	.dc.b	'DELDRV.X',0

mdevice_sys_name:
	.dc.b	'MDEVICE.SYS #/B9',0

config_name:
	.dc.b	'EMEDRA.CNF',0

*ミュージックドライバのデバイス名
emdrive_name:
	.dc.b	'EMDRIVE',0

*プログラム実行時のダミーのコマンドライン
emopen_command_line:
emedra_command_line:
mode_command_line:
	.dc.b	0,0

*emedra.x 格納パス
emedra_path:
	.dc.b	'EMEDRA\',0

*emopen.x 格納パス
bin_path:
	.dc.b	'BIN\',0

sysdata_path:
	.dc.b	'SYSDATA',0
	.dc.b	'MAPDATA',0
	.dc.b	'MOVER',0
	.dc.b	'MUSIC',0
	.dc.b	'TALKDATA',0
	.dc.b	'FIGHTDATA',0
	.dc.b	'VISDATA',0
userdata_path:
	.dc.b	'USERDATA',0
	.dc.b	$ff		* パス名リスト終了コード

sysdata_path_check_mes:
	.dc.b	'SYS',0
	.dc.b	'MAP',0
	.dc.b	'MOVER',0
	.dc.b	'MUSIC',0
	.dc.b	'TALK',0
	.dc.b	'FIGHT',0
	.dc.b	'VISUAL',0
	.dc.b	'USER',0
	.dc.b	$ff		* チェック文字リスト終了コード


**********************************************************************
* スイッチ保存情報，フラグ
**********************************************************************
game_switch_flag:
	.dc.b	0		* -G:ゲームなら０以外

music_mode_switch_flag:
	.dc.b	0		* -M:ミュージックモードなら０以外

opening_switch_flag:
	.dc.b	0		* -O:オープニングを実行するなら０以外

zoo_switch_flag:
	.dc.b	0		* -Z:ずうスイッチ指定なら０以外

emedra_path_set_flag:
	.dc.b	0		* パス名が指定されたら０以外

ex_map_flag:
	.dc.b	0		* どこでもマップパッチ有無

ex_scroll_flag:
	.dc.b	0		* 移動高速化パッチ有無

ex_battle_flag:
	.dc.b	0		* 戦闘高速化パッチ有無

ex_exp_flag:
	.dc.b	0		* 経験値２倍パッチ有無

ex_super_flag:
	.dc.b	0		* ほぼ最強装備パッチ有無

ex_zoo_flag:
	.dc.b	0		* ずう隠しパッチ有無

tdpause_flag:
	.dc.b	0		* TIMER-D停止が必要なら０以外

adddrv_use_flag:
	.dc.b	0		* ADDDRVを使ったなら０以外

**********************************************************************
* ワーク領域
**********************************************************************

	.bss
	.even

himem_pointer:
	.ds.l	1

start_a0_backup:
	.ds.l	1		* EMEDRA_patch.x 実行直後のa0（メモリ管理ポインタ）

program_top_address:
	.ds.l	1

program_exec_address:
	.ds.l	1

last_patch_address:
	.ds.l	1		* パッチで最後に書き換えた場所

emedra_exe_exit_code:
	.ds.l	1		* emedra.x のexit値

iocs6b_vector_backup:
	.ds.l	1		* IOCS _TIMERDST ($05ac.w) のベクタを保存する

timerd_vector_backup:
	.ds.l	1		* MFP TIMER-D ($0110.w) のベクタを保存する

key_led_backup:
	.ds.b	1		* ゲーム開始前のキーLED状態を保存

key_led_new:
	.ds.b	1		* ゲーム開始時のLED状態

emedra_all_path:
	.ds.b	64+1		* ハードディスクにインストールしたパス

files_buffer:			* DOS _FILES ($ff4e) で使うバッファ 53バイト
get_pr_buffer:			* DOS _GET_PR ($fffa) で使うバッファ 116バイト
	.ds.b	116

exe_load_path:			* プログラムを読み込むパス名
set_path_buf:			* パス名をemedra.xに登録するバッファ
	.ds.b	64+1

config_file_name:		* 
adddrv_file_name:		* adddrv実行ファイル名（パス付き） 90バイト
deldrv_file_name:		* deldrv実行ファイル名（パス付き） 90バイト
file_name_buf:
	.ds.b	128+1

adddrv_command_line:		* adddrv実行時のコマンドライン
deldrv_command_line:		* deldrv実行時のコマンドライン
	.ds.b	256

*スタック
	.ds.b	2048

	.even
user_sp:
	.end	emedra_patch

