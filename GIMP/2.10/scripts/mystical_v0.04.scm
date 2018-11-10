;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	This program is free software: you can redistribute it and/or modify								;;
;	it under the terms of the GNU General Public License as published by								;;
;	the Free Software Foundation, either version 3 of the License, or									;;
;	(at your option) any later version.																	;;
;																										;;
;	This program is distributed in the hope that it will be useful,										;;
;	but WITHOUT ANY WARRANTY without even the implied warranty of										;;
;	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the										;;
;	GNU General Public License for more details.														;;
;																										;;
;	You should have received a copy of the GNU General Public License									;;
;	along with this program.  If not, see <http://www.gnu.org/licenses/>.								;;
;																										;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	v0.04 Mystical; Gimp v2.10																			;;
;;	(de) http://www.3d-hobby-art.de/news/196-gimp-script-fu-mythical.html								;;
;;	(eng) http://www.3d-hobby-art.de/en/blog/197-gimp-script-fu-mythical.html							;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(script-fu-register
	"script-fu-mythical"												;func name
	"Mythical (free) ..."												;menu label
	"Create awesome atmospheric lighting and Mystical effect."			;desc
	"Stephan W."
	"(c) 2016, 3d-hobby-art.de"											;copyright notice
	"Mai 30, 2016"														;date created
	"RGBA , RGB"														;image type that the script works on
	SF-IMAGE		"Image"						0
	SF-DRAWABLE		"The layer"					0
	SF-COLOR		_"Add background"			'(0 0 0)
	SF-ADJUSTMENT	_"Farbverlaufsbreite"		'(2500 0 8000 10 100 0 0)
	SF-OPTION		_"Gradient"					'("FG to BG (RGB) (en)" "VG nach HG (RGB) (de)")
	SF-OPTION		_"Direction"				'("Top Right to Bottom Left" "Top Left to Bottom Right")
	SF-TOGGLE		"Run Interactive Mode?"		FALSE
)
(script-fu-menu-register "script-fu-mythical" "<Image>/Script-Fu/Mythical")

(define (script-fu-mythical img drawable inBgColor inLightWidth inGradientName inLightDirection inRunMode)

	(define (get-base-layer new-layer-marker)
		(let* (
				(parent (car (gimp-item-get-parent new-layer-marker)))
				(siblings 
					(if (= -1 parent)
						(vector->list (cadr (gimp-image-get-layers img)))
						(vector->list (cadr (gimp-item-get-children parent))) 
					)
				)
			)
			(let 
			loop ((layers (cdr (memv new-layer-marker siblings))))
			   (if (= (car (gimp-item-get-visible (car layers))) TRUE)
				 (car layers)
				 (loop (cdr layers)))
			)
		)
	)
	;;
	(define (gimp-message-and-quit message)
		(let  
			;;
			((old-handler (car (gimp-message-get-handler))) )
			(gimp-message-set-handler MESSAGE-BOX)
			(gimp-message message)
			;;
			(gimp-message-set-handler old-handler)
			(quit)
		)
	)
	; repeat func move Layer
	(define else #t)
	(define (my-duplicate-layer img layer)
		(let* ((dup-layer (car (gimp-layer-copy layer 1)))) (gimp-image-add-layer img dup-layer 1) dup-layer)
	)
	(define (repeat func times)
		(cond ((> times 0)
			(cons (func)
				(repeat func (- times 1))))
				(else '())
		)
	)

	(let* ( 
			(bg-layer (car (gimp-image-get-layer-by-name img "background")))
			(brush-mask-layer (car (gimp-image-get-layer-by-name img "brush-mask")))
			(ImageWidth  (car (gimp-image-width  img)))
			(ImageHeight (car (gimp-image-height img)))
			(old-bg (car (gimp-context-get-background)))
			(old-fg (car (gimp-context-get-foreground)))
			(new-layer-marker (car (gimp-layer-new img 100 100 RGBA-IMAGE "marker (tmp)" 100 NORMAL)))
			(new-bg-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "background-fill" 100 NORMAL)))
			(object-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "faded off object" 100 NORMAL)))
			(object-group (car (gimp-layer-group-new img)))
			(Ls)
			(ls-layer-mask)
			(gradient-layer)
			(light-group)
			(streaks-layer)
			(streaks-layer-mask)
			(streaks-layer-copy)
			(streaks-layer-copy2)
			(move-layer)
			(lmap-layer)
			(main-light-layer)
			(main-light-layer-mask)
			(floating-selection)
			(object-fade-off-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "object fade off" 100 NORMAL)))
			(object-fade-off-layer-mask (car (gimp-layer-create-mask object-fade-off-layer ADD-WHITE-MASK)))
			(mo-layer) ;;
			(main-object-layer-mask) ;;
			(light-zoom-layer)
			(contrast-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "contrast" 100 NORMAL)))
			(clouds-layer (car (gimp-layer-new img (* ImageWidth 1.3) (* ImageHeight 1.3) RGBA-IMAGE "clouds (texture)" 25 SOFTLIGHT-MODE)))
			(grain-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "Grain" 20 OVERLAY-MODE)))
			(grain-shadow-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "Grain - shadows" 70 DARKEN-ONLY-MODE)))
			(noise-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "noise" 100 SCREEN-MODE)))
			(color-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "color" 50 SOFTLIGHT-MODE)))
			(seed)
			(object-layer-high-pass)
			(object-layer-high-pass-dupl)
		)

		;;
		(if  ( = (car (gimp-image-get-layer-by-name img "background")) -1)
			(gimp-message-and-quit "There is no \"background\" layer! Tutorial - please read. \n Keine \"background\" -Ebene gefunden! Bitte lesen Sie mein Tutorial.")
		)
		(if  ( = (car (gimp-image-get-layer-by-name img "brush-mask")) -1)
			(gimp-message-and-quit "There is no \"brush-mask\" layer! Tutorial - please read. \n Keine \"brush-mask\" -Ebene gefunden! Bitte lesen Sie mein Tutorial.")
		)

		(gimp-image-undo-group-start img)

		(gimp-context-set-foreground '(0 0 0))
		(gimp-context-set-background '(255 255 255))

		;;
		(gimp-image-set-active-layer img bg-layer)

		;;
		;; ************************************************************************************************************************************
		(gimp-image-add-layer img new-layer-marker 0)
		(gimp-image-set-active-layer img new-layer-marker)
		(gimp-context-set-background '(245 0 0))
		(gimp-edit-fill new-layer-marker BACKGROUND-FILL)
		;;
		(gimp-image-set-active-layer img new-layer-marker)
		(let* ( 
				(base-x 0)
				(base-y 0)
				(base-layer (get-base-layer new-layer-marker))
				(base-width (car (gimp-image-width  img)))
				(base-height (car (gimp-image-height img)))
			)
				(set! base-x (car  (gimp-drawable-offsets base-layer)))
				(set! base-y (cadr (gimp-drawable-offsets base-layer)))
				(set! base-width  (car (gimp-drawable-width  base-layer)))
				(set! base-height (car (gimp-drawable-height base-layer)))
				;;
				(gimp-layer-set-offsets new-layer-marker (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)))
				;;
				(gimp-item-set-visible new-layer-marker FALSE)
		)


		;;
		;; ************************************************************************************************************************************
		(gimp-image-add-layer img new-bg-layer 2)
		(gimp-image-set-active-layer img new-bg-layer)
		(gimp-context-set-background inBgColor)
		(gimp-edit-fill new-bg-layer BACKGROUND-FILL)

		;;
		;; ************************************************************************************************************************************
		(gimp-selection-layer-alpha brush-mask-layer)
		(gimp-item-set-visible brush-mask-layer FALSE)

		;;
		;; ************************************************************************************************************************************
		(gimp-item-set-lock-content bg-layer TRUE)
		(gimp-edit-copy bg-layer)

		;;
		;; ************************************************************************************************************************************
		(gimp-image-add-layer img object-layer 2)
		(set! object-layer (car (gimp-edit-paste object-layer FALSE)))
		(gimp-floating-sel-to-layer object-layer)
		(gimp-image-merge-down img object-layer CLIP-TO-BOTTOM-LAYER)

		;;
		;; ************************************************************************************************************************************
		(gimp-item-set-name object-group "Object Group")
		(gimp-layer-set-mode object-group NORMAL-MODE)
		(gimp-layer-set-opacity object-group 100)
		(gimp-image-insert-layer img object-group 0 2)

		;;
		;; ************************************************************************************************************************************
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "faded off object")) object-group 0)

		;;
		;; ************************************************************************************************************************************
		(set! Ls (car (gimp-layer-new-from-visible img img "Ls (tmp)")))
		(gimp-image-add-layer img Ls 2)

		(if (= inLightDirection 0)
			;;
			;; *********************************************************************************************************
			(python-layerfx-gradient-overlay RUN-NONINTERACTIVE img Ls "Flare Rays - 3d-hobby-art.de" GRADIENT-LINEAR REPEAT-NONE FALSE 100 NORMAL-MODE (/ ImageWidth 2) (/ ImageWidth 2) -40 inLightWidth FALSE)
			(if (= inLightDirection 1)
				;;
				;; *********************************************************************************************************
				(python-layerfx-gradient-overlay RUN-NONINTERACTIVE img Ls "Flare Rays - 3d-hobby-art.de" GRADIENT-LINEAR REPEAT-NONE FALSE 100 NORMAL-MODE (/ ImageWidth 2) (/ ImageWidth 2) 40 inLightWidth FALSE)
			)

		)

		;;
		(gimp-image-remove-layer img Ls)
		;;
		(set! light-group (car (gimp-image-get-layer-by-name img "Ls (tmp)-with-gradient")))
		(set! gradient-layer (car (gimp-image-get-layer-by-name img "Ls (tmp)-gradient")))
		(gimp-layer-set-name light-group "Lighting Setup")
		(gimp-layer-set-name gradient-layer "light source (tmp)")


		;;
		;; ************************************************************************************************************************************
		(set! streaks-layer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "faded off object")) 0)))
		(gimp-image-insert-layer img streaks-layer light-group 0)
		(gimp-layer-set-name streaks-layer "light streaks")
		(gimp-image-set-active-layer img streaks-layer)
		(let* (
				(base-x 0)
				(base-y 0)
				(base-layer (get-base-layer new-layer-marker))
				(base-width (car (gimp-image-width  img)))
				(base-height (car (gimp-image-height img)))
			)
				(set! base-x (car  (gimp-drawable-offsets base-layer)))
				(set! base-y (cadr (gimp-drawable-offsets base-layer)))
				(set! base-width  (car (gimp-drawable-width  base-layer)))
				(set! base-height (car (gimp-drawable-height base-layer)))
				(if (= inLightDirection 0)
					;;
					;; *********************************************************************************************************
					(plug-in-mblur RUN-NONINTERACTIVE img streaks-layer LINEAR 1330 -50 (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)))
						(if (= inLightDirection 1)
							;;
							;; *********************************************************************************************************
							(plug-in-mblur RUN-NONINTERACTIVE img streaks-layer LINEAR 1330 230 (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)))
						)
				)
		)

		;
		; ************************************************************************************************************************************
		(set! move-layer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "faded off object")) 0)))
		(gimp-image-add-layer img move-layer 2)
		(gimp-layer-set-name move-layer "move (tmp)")
		(gimp-image-set-active-layer img move-layer)
		(if (= inLightDirection 0)
			;;
			(gimp-layer-translate move-layer -10 10)
			(if (= inLightDirection 1)
				;;
				(gimp-layer-translate move-layer 10 10)
			)
		)

		(let (
			(pos-x 0)
			(pos-y 0)
			(step 10)
			(layers (repeat (lambda () (my-duplicate-layer img (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "move (tmp)")) 0))))
				(- 111 1)))
		)
		(for-each (lambda (x)
			(if (= inLightDirection 0)
				;;
				(set! pos-x (- pos-x step))
					(if (= inLightDirection 1)
						;;
						(set! pos-x (+ pos-x step))
					)
			)
			(set! pos-y (+ pos-y step))
			(gimp-layer-translate x pos-x pos-y)
			)
			layers)
		)

		;;
		(gimp-item-set-visible bg-layer FALSE)
		(gimp-item-set-visible new-bg-layer FALSE)
		(gimp-item-set-visible light-group FALSE)
		(gimp-item-set-visible object-group FALSE)
		;;
		(gimp-image-merge-visible-layers img CLIP-TO-BOTTOM-LAYER)

		;;
		(gimp-item-set-visible light-group TRUE)
		(gimp-item-set-visible object-group TRUE)
		(gimp-item-set-visible new-bg-layer TRUE)

		;;
		;; ************************************************************************************************************************************
		(set! lmap-layer (gimp-layer-set-name (car (gimp-image-get-layer-by-name img "move (tmp)")) "Light map (tmp)"))
		(set! lmap-layer (gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "Light map (tmp)"))))
		(gimp-selection-feather img 40)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "Light map (tmp)")) FALSE)

		;;
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img streaks-layer)
		(set! streaks-layer-mask (car (gimp-layer-create-mask streaks-layer ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img streaks-layer streaks-layer-mask)
		(gimp-layer-remove-mask streaks-layer MASK-APPLY)
		(gimp-selection-none img)
		(if (= inLightDirection 0)
			;;
			(gimp-layer-translate streaks-layer -177 270)
				(if (= inLightDirection 1)
					;;
					(gimp-layer-translate streaks-layer 177 270)
				)
		)

		(let* (
			(base-x 0)
			(base-y 0)
			(base-layer (get-base-layer new-layer-marker))
			(base-width (car (gimp-image-width  img)))
			(base-height (car (gimp-image-height img)))
		)
			(set! base-x (car  (gimp-drawable-offsets base-layer)))
			(set! base-y (cadr (gimp-drawable-offsets base-layer)))
			(set! base-width  (car (gimp-drawable-width  base-layer)))
			(set! base-height (car (gimp-drawable-height base-layer)))
			(if (= inLightDirection 0)
				;;
				;; *********************************************************************************************************
				(plug-in-mblur RUN-NONINTERACTIVE img streaks-layer LINEAR 235 -50 (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)))
					(if (= inLightDirection 1)
						;;
						;; *********************************************************************************************************
						(plug-in-mblur RUN-NONINTERACTIVE img streaks-layer LINEAR 235 50 (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)))
					)
			)
		)

		;;
		(set! streaks-layer-copy (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "light streaks")) 0)))
		(gimp-image-add-layer img streaks-layer-copy 3)
		(gimp-layer-set-name streaks-layer-copy "light streaks -copy (tmp)")
		(gimp-image-set-active-layer img streaks-layer-copy)

		(set! streaks-layer-copy2 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "light streaks -copy (tmp)")) 0)))
		(gimp-image-add-layer img streaks-layer-copy2 3)
		(gimp-layer-set-name streaks-layer-copy2 "light streaks -copy (tmp) #2")
		(gimp-image-set-active-layer img streaks-layer-copy2)
		(gimp-image-merge-down img streaks-layer-copy2 CLIP-TO-BOTTOM-LAYER)

		;;
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "light streaks -copy (tmp)")))
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "light streaks -copy (tmp)")) FALSE)

		;;
		(gimp-context-set-background '(0 0 0))
		(set! ls-layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "light source (tmp)")) ADD-WHITE-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "light source (tmp)")) ls-layer-mask)
		(gimp-edit-fill ls-layer-mask BACKGROUND-FILL)
		(gimp-edit-fill ls-layer-mask BACKGROUND-FILL)

		(let* (
				(base-x 0)
				(base-y 0)
				(base-layer (get-base-layer new-layer-marker))
				(base-width (car (gimp-image-width  img)))
				(base-height (car (gimp-image-height img)))
			)
			(set! base-x (car  (gimp-drawable-offsets base-layer)))
			(set! base-y (cadr (gimp-drawable-offsets base-layer)))
			(set! base-width  (car (gimp-drawable-width  base-layer)))
			(set! base-height (car (gimp-drawable-height base-layer)))
			(if (= inLightDirection 0)
				;;
				;; *********************************************************************************************************
				(plug-in-mblur RUN-NONINTERACTIVE img ls-layer-mask LINEAR 350 -50 (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)))
					(if (= inLightDirection 1)
						;;
						;; *********************************************************************************************************
						(plug-in-mblur RUN-NONINTERACTIVE img ls-layer-mask LINEAR 350 50 (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)))
					)
			)
		)
		(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img ls-layer-mask 10 10 1)
		;;
		(gimp-selection-all img)
		(gimp-edit-copy ls-layer-mask)
		(gimp-selection-none img)

		;;
		(gimp-image-set-active-layer img streaks-layer)
		(gimp-desaturate-full streaks-layer DESATURATE-LIGHTNESS)

		;;
		(gimp-item-set-visible streaks-layer FALSE)
		(gimp-item-set-visible object-group FALSE)

		;;
		;; ************************************************************************************************************************************
		(set! main-light-layer (car (gimp-layer-new-from-visible img img "main light")))
		(set! main-light-layer-mask (car (gimp-layer-create-mask main-light-layer ADD-WHITE-MASK)))
		(gimp-image-insert-layer img main-light-layer light-group 1)
		(let* (
				(base-x 0)
				(base-y 0)
				(base-layer (get-base-layer new-layer-marker))
				(base-width (car (gimp-image-width  img)))
				(base-height (car (gimp-image-height img)))
			)
			(set! base-x (car  (gimp-drawable-offsets base-layer)))
			(set! base-y (cadr (gimp-drawable-offsets base-layer)))
			(set! base-width  (car (gimp-drawable-width  base-layer)))
			(set! base-height (car (gimp-drawable-height base-layer)))
			;;
			;; *********************************************************************************************************
			(plug-in-mblur RUN-NONINTERACTIVE img main-light-layer RADIAL 30 0 (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)))
		)
		(gimp-image-add-layer-mask img main-light-layer main-light-layer-mask)
		;;
		(set! floating-selection (car (gimp-edit-paste main-light-layer-mask 0)))
		(gimp-floating-sel-anchor floating-selection)

		;;
		(gimp-item-set-visible streaks-layer TRUE)
		(gimp-item-set-visible object-group TRUE)

		;;
		(gimp-edit-copy (car (gimp-image-get-layer-by-name img "faded off object")))


		(gimp-image-add-layer img object-fade-off-layer 4)
		(set! floating-selection (car (gimp-edit-paste object-fade-off-layer 0)))
		(gimp-floating-sel-anchor floating-selection)
		(gimp-image-add-layer-mask img object-fade-off-layer object-fade-off-layer-mask)
		;;
		(gimp-edit-copy (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "light source (tmp)")))))
		;;
		(set! floating-selection (car (gimp-edit-paste object-fade-off-layer-mask 0)))
		(gimp-floating-sel-anchor floating-selection)
		(gimp-invert object-fade-off-layer-mask)
		;;
		;; *********************************************************************************************************
		(python-layerfx-color-overlay (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "object fade off")) '(0 0 0) 100 NORMAL-MODE FALSE)
		;;
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "object fade off")) object-group 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "object fade off-color")) object-group 0)
		(gimp-layer-set-name (car (gimp-image-get-layer-by-name img "object fade off-color")) "object fade off -overlay")
		;;
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "object fade off-with-color")))

		;;
		(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "faded off object")) 24)
		(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "light streaks")) 30)

		;;
		;; ************************************************************************************************************************************
		(set! mo-layer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "faded off object")) 0)))
		(gimp-image-add-layer img mo-layer 4)
		(gimp-layer-set-name mo-layer "main object (tmp)")
		(gimp-context-set-foreground '(0 0 0))
		(gimp-context-set-background '(255 255 255))
		;;
		;; *********************************************************************************************************
		(let* (
				(base-x 0)
				(base-y 0)
				(base-layer (get-base-layer new-layer-marker))
				(base-width (car (gimp-image-width  img)))
				(base-height (car (gimp-image-height img)))
			)
			(set! base-x (car  (gimp-drawable-offsets base-layer)))
			(set! base-y (cadr (gimp-drawable-offsets base-layer)))
			(set! base-width  (car (gimp-drawable-width  base-layer)))
			(set! base-height (car (gimp-drawable-height base-layer)))
			(if (= inLightDirection 0)
				;;
				;; *********************************************************************************************************
				(python-layerfx-gradient-overlay RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "main object (tmp)")) (if (= inGradientName 0) "FG to BG (RGB)" (if (= inGradientName 1) "VG nach HG (RGB)")) GRADIENT-LINEAR REPEAT-NONE TRUE 100 NORMAL-MODE (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)) -120 700 FALSE)
					(if (= inLightDirection 1)
						;;
						;; *********************************************************************************************************
						(python-layerfx-gradient-overlay RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "main object (tmp)")) (if (= inGradientName 0) "FG to BG (RGB)" (if (= inGradientName 1) "VG nach HG (RGB)")) GRADIENT-LINEAR REPEAT-NONE FALSE 100 NORMAL-MODE (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)) 120 700 FALSE)
					)
			)
		)

		;;
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "main object (tmp)")) FALSE)
		(gimp-item-set-visible streaks-layer FALSE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "light source (tmp)")) FALSE)
		;;
		(gimp-edit-copy-visible img)

		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "main object (tmp)")) TRUE)
		(set! main-object-layer-mask (car (gimp-layer-create-mask mo-layer ADD-WHITE-MASK)))
		;;
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "main object (tmp)")) main-object-layer-mask)
		(set! floating-selection (car (gimp-edit-paste main-object-layer-mask 0)))
		(gimp-floating-sel-anchor floating-selection)
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "main object (tmp)-gradient")))
		;;
		(gimp-layer-set-name (car (gimp-image-get-layer-by-name img "main object (tmp)-with-gradient")) "main object -group")
		(gimp-layer-set-name (car (gimp-image-get-layer-by-name img "main object (tmp)")) "main object")
		;;
		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "main object -group")) SOFTLIGHT-MODE)
		(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "main object")) 100)


		;;
		;; ************************************************************************************************************************************
		(set! light-zoom-layer (car (gimp-layer-new-from-visible img img "Light source zoom")))
		(gimp-image-add-layer img light-zoom-layer 4)

		(let* (
				(base-x 0)
				(base-y 0)
				(base-layer (get-base-layer new-layer-marker))
				(base-width (car (gimp-image-width  img)))
				(base-height (car (gimp-image-height img)))
			)
			(set! base-x (car  (gimp-drawable-offsets base-layer)))
			(set! base-y (cadr (gimp-drawable-offsets base-layer)))
			(set! base-width  (car (gimp-drawable-width  base-layer)))
			(set! base-height (car (gimp-drawable-height base-layer)))
			;;
			;; *********************************************************************************************************
			(plug-in-mblur RUN-NONINTERACTIVE img light-zoom-layer 2 90 0 (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)))
		)
		(gimp-layer-set-mode light-zoom-layer SCREEN-MODE)
		(gimp-layer-set-opacity light-zoom-layer 24)
		(gimp-desaturate-full light-zoom-layer DESATURATE-LIGHTNESS)
		;;
		(gimp-context-set-interpolation INTERPOLATION-CUBIC)
		(gimp-layer-scale light-zoom-layer (* ImageWidth 1.5) (* ImageHeight 1.5) TRUE)

		;;
		;; ************************************************************************************************************************************
		(gimp-image-add-layer img contrast-layer 4)
		(gimp-context-set-foreground '(0 0 0))
		(gimp-context-set-background '(255 255 255))
		(gimp-edit-fill contrast-layer BACKGROUND-FILL)
		(let* (
				(base-x 0)
				(base-y 0)
				(base-layer (get-base-layer new-layer-marker))
				(base-width (car (gimp-image-width  img)))
				(base-height (car (gimp-image-height img)))
			)
			(set! base-x (car  (gimp-drawable-offsets base-layer)))
			(set! base-y (cadr (gimp-drawable-offsets base-layer)))
			(set! base-width  (car (gimp-drawable-width  base-layer)))
			(set! base-height (car (gimp-drawable-height base-layer)))
			(if (= inLightDirection 0)
			;;
			;; *********************************************************************************************************
			(python-layerfx-gradient-overlay RUN-NONINTERACTIVE img contrast-layer (if (= inGradientName 0) "FG to BG (RGB)" (if (= inGradientName 1) "VG nach HG (RGB)")) GRADIENT-LINEAR REPEAT-NONE FALSE 100 NORMAL-MODE (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)) 0 (- ImageWidth (/ ImageWidth 3)) TRUE)
					(if (= inLightDirection 1)
						;;
						;; *********************************************************************************************************
						(python-layerfx-gradient-overlay RUN-NONINTERACTIVE img contrast-layer (if (= inGradientName 0) "FG to BG (RGB)" (if (= inGradientName 1) "VG nach HG (RGB)")) GRADIENT-LINEAR REPEAT-NONE TRUE 100 NORMAL-MODE (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)) 0 (- ImageWidth (/ ImageWidth 3)) TRUE)
					)
			)
		)
		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "contrast")) OVERLAY-MODE)
		(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "contrast")) 90)

		;;
		;; ************************************************************************************************************************************
		(gimp-image-add-layer img clouds-layer 5)
		(set! seed (if (number? seed) seed (realtime)))
		(plug-in-plasma RUN-NONINTERACTIVE img clouds-layer (srand seed) 3)
		(gimp-desaturate-full clouds-layer DESATURATE-LIGHTNESS)

		;;
		;; ************************************************************************************************************************************
		(gimp-context-set-foreground '(128 128 128))
		(gimp-drawable-fill grain-layer FOREGROUND-FILL)
		(gimp-drawable-fill grain-shadow-layer FOREGROUND-FILL)
		(gimp-image-add-layer img grain-layer 5)
		(gimp-image-add-layer img grain-shadow-layer 5)
		(plug-in-hsv-noise TRUE img grain-layer 2 0 0 100)
		(gimp-context-set-antialias TRUE)
		(gimp-context-set-feather TRUE)
		(gimp-context-set-feather-radius 4 3)
		(gimp-context-set-sample-merged TRUE)
		(gimp-image-select-color img CHANNEL-OP-REPLACE (car (gimp-image-get-layer-by-name img "main light")) '(35 35 35))
		(plug-in-hsv-noise TRUE img grain-shadow-layer 2 0 0 100)
		(gimp-selection-none img)
		(plug-in-colortoalpha RUN-NONINTERACTIVE img grain-shadow-layer '(128 128 128))
		(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img grain-shadow-layer 3 3 1)

		;;
		;; ************************************************************************************************************************************
		(gimp-image-add-layer img noise-layer 5)
		(gimp-context-set-background inBgColor)
		(gimp-edit-fill noise-layer BACKGROUND-FILL)
		(plug-in-rgb-noise (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img noise-layer FALSE FALSE 0.03 0.03 0.03 0.03)

		;;
		;; ************************************************************************************************************************************
		(gimp-image-add-layer img color-layer 4)
		(gimp-context-set-background '(216 124 124))
		(gimp-edit-fill color-layer BACKGROUND-FILL)
		(python-layerfx-color-overlay (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img color-layer '(255 230 230) 100 MULTIPLY-MODE FALSE)
		(gimp-layer-set-name (car (gimp-image-get-layer-by-name img "color-with-color")) "Red Color (option)")
		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "Red Color (option)")) SOFTLIGHT-MODE)

		;; 
		;; ************************************************************************************************************************************
		(set! object-layer-high-pass (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "faded off object")) 0)))
		(gimp-image-insert-layer img object-layer-high-pass (car (gimp-image-get-layer-by-name img "main object -group")) 0)
		(gimp-layer-set-opacity object-layer-high-pass 100)
		(gimp-layer-set-name object-layer-high-pass "object (highPass)")
		(set! object-layer-high-pass-dupl (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object (highPass)")) 0)))
		(gimp-image-insert-layer img object-layer-high-pass-dupl (car (gimp-image-get-layer-by-name img "main object -group")) 0)
		(gimp-invert object-layer-high-pass-dupl)
		(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img object-layer-high-pass-dupl (/ ImageWidth 80) (/ ImageWidth 80) 1)
		(gimp-layer-set-opacity object-layer-high-pass-dupl 50)
		(gimp-image-merge-down img object-layer-high-pass-dupl CLIP-TO-BOTTOM-LAYER)
		(gimp-brightness-contrast (car (gimp-image-get-layer-by-name img "object (highPass)")) 0 90)
		(gimp-desaturate-full (car (gimp-image-get-layer-by-name img "object (highPass)")) DESATURATE-AVERAGE)
		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "object (highPass)")) OVERLAY-MODE)


		;;
		;; ************************************************************************************************************************************
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "light streaks -copy (tmp)")))
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "Light map (tmp)")))
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "marker (tmp)")))
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "light source (tmp)")))
		(gimp-layer-set-visible (car (gimp-image-get-layer-by-name img "light streaks")) TRUE)
		(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img main-light-layer-mask 20 20 1)
		(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img object-fade-off-layer-mask 30 30 1)
		(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "faded off object")) 90)

		;;
		(gimp-selection-none img)

		;;
		(gimp-palette-set-background old-bg)
		(gimp-palette-set-foreground old-fg)
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Red Color (option)")))
		(gimp-image-undo-group-end img)

		(gimp-displays-flush)
	)
)