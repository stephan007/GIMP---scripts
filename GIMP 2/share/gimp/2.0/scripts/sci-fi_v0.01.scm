;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	This program is free software: you can redistribute it and/or modify								;;
;	it under the terms of the GNU General Public License as published by								;;
;	the Free Software Foundation, either version 3 of the License, or									;;
;	(at your option) any later version.																	;;
;																										;;
;	This program is distributed in the hope that it will be useful,										;;
;	but WITHOUT ANY WARRANTY without even the implied warranty of										;;
;	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the										;;
;	GNU General Public License for more details.														;;
;																										;;
;	You should have received a copy of the GNU General Public License									;;
;	along with this program.  If not, see <http://www.gnu.org/licenses/>.								;;
;																										;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	v0.01 Sci-Fi; Gimp v2.8.16																			;;
;;	(de) http://www.3d-hobby-art.de/news/200-gimp-script-fu-sci-fi.html									;;
;;	(eng) http://www.3d-hobby-art.de/en/blog/201-gimp-script-fu-sci-fi.html								;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(script-fu-register
	"script-fu-sci-fi"														;func name
	"Sci-fi ..."															;menu label
	"Sci-fi Script turns your photos into futuristic Sci-Fi composition."	;desc
	"Stephan W."
	"Stephan Wittling; (c) 2016, 3d-hobby-art.de"							;copyright notice
	"Juli 02, 2016"															;date created
	"RGBA, RGB"																;image type that the script works on
	SF-IMAGE		"Image"						0
	SF-DRAWABLE		"The layer"					0
	SF-COLOR		_"Add background"			'(5 5 5)
	SF-COLOR		_"Color"					'(0 234 255)	;; ScFi-color
	SF-COLOR		_"Color"					'(0 192 255)	;; ScFi-color inside "sci-fi-brush" layer (darker)
	SF-COLOR		_"Glow"						'(80 241 255)	;; ScFi-color inside "sci-fi-brush" layer (darker glow)
	SF-ADJUSTMENT	"Hexagon Amount"			'(50 20 250 10 10 0 0)
	SF-OPTION		_"Gradient"					'("FG to Transparent (en)" "VG nach Transparent (de)")		;; radial Background
	SF-STRING		_"Brush name"				"sandstorm_brushes_by_nykkida-d3jry4w.abr-002"				;; inUserBrush (abstract backgounds)
	SF-STRING		_"Brush name"				"scfi TechBrush -Flame opacity"								;; inUserBrushOpacity
	SF-STRING		_"Brush name"				"scfi TechBrush 001"										;; inUserBrushCircle (donate: "scfi TechBrush 001", "scfi TechBrush 002")
	SF-TOGGLE		"Run Interactive Mode?"		FALSE
	SF-TOGGLE		"Undo Mode?"				FALSE
)
(script-fu-menu-register "script-fu-sci-fi" "<Image>/Script-Fu/Sci-Fi Effect")

(define (script-fu-sci-fi img drawable inBgColor inScFiColor inScFiInsideColor inScFiInsideGlowColor inAmount inGradientName inUserBrush inUserBrushOpacity inUserBrushCircle inRunMode inUndoMode)

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

	; repeat func
	(define else #t)
	(define (my-duplicate-layer img layer)
		(let* ((dup-layer (car (gimp-layer-copy layer 1)))) (gimp-image-insert-layer img dup-layer 0 -1) dup-layer)
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
			(brush-mask-layer (car (gimp-image-get-layer-by-name img "area-brush")))
			(sci-fi-mask-layer (car (gimp-image-get-layer-by-name img "sci-fi-brush")))
			(ImageWidth  (car (gimp-image-width  img)))
			(ImageHeight (car (gimp-image-height img)))
			(old-bg (car (gimp-context-get-background)))
			(old-fg (car (gimp-context-get-foreground)))
			(new-layer-marker (car (gimp-layer-new img 100 100 RGBA-IMAGE "marker (tmp)" 100 NORMAL)))
			(fill-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "background-color" 100 NORMAL)))
			(path-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "sci-fi-path" 100 NORMAL)))
			(path-layer2 (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "sci-fi-path 2" 100 NORMAL)))
			(path-layer3 (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "sci-fi-path 3" 100 NORMAL)))
			(vector-path)
			(gradient-layer-radial (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "gradient-fill" 100 NORMAL)))

			(sci-fi-layer-group (car (gimp-layer-group-new img)))
			(sci-fi-layer3 (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "abstract bg #1 (dark)" 70 NORMAL)))
			(sci-fi-layer4 (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "abstract bg #2 (bright)" 14 NORMAL)))
			(sci-fi-layer2 (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "abstract bg #3 (dark)" 60 NORMAL)))
			(sci-fi-layer5 (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "abstract bg #4 (bright)" 11 NORMAL)))
			(sci-fi-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "abstract bg #5 (dark)" 30 NORMAL)))

			(brush-layer-group (car (gimp-layer-group-new img)))
			(sci-fi-layer6 (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "hexagon particles glow (outside)" 100 NORMAL)))
			(sci-fi-layer7 (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "abstract web (inside)" 100 NORMAL)))
			(sci-fi-layer8 (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "abstract web (outside)" 100 NORMAL)))
			(sci-fi-layer9 (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "object light" 100 NORMAL)))
			(sci-fi-layer10 (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "hexagons web (border)" 100 NORMAL)))
			(seed)
			(owidth)
			(oheight)
			(npoint 4)
			(smoke-count 0)
			(smoke-count2 0)
			(smoke-count3 0)
			(smoke-count4 0)
			(smoke-count5 0)
			(ornament-count 0)
			(floating-selection)
		)

		;;
		(if  ( = (car (gimp-image-get-layer-by-name img "background")) -1)
			(gimp-message-and-quit "There is no \"background\" layer! Tutorial - please read. \n Keine \"background\" -Ebene gefunden! Bitte lesen Sie mein Tutorial.")
		)
		(if  ( = (car (gimp-image-get-layer-by-name img "area-brush")) -1)
			(gimp-message-and-quit "There is no \"area-brush\" layer! Tutorial - please read. \n Keine \"area-brush\" -Ebene gefunden! Bitte lesen Sie mein Tutorial.")
		)
		(if  ( = (car (gimp-image-get-layer-by-name img "sci-fi-brush")) -1)
			(gimp-message-and-quit "There is no \"sci-fi-brush\" layer! Tutorial - please read. \n Keine \"sci-fi-brush\" -Ebene gefunden! Bitte lesen Sie mein Tutorial.")
		)

		;;
		(if (= inUndoMode TRUE) (begin (gimp-image-undo-group-start img)) )
		(gimp-context-push)

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

		;;
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "sci-fi-brush")) FALSE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "area-brush")) FALSE)

		;;
		(gimp-image-set-active-layer img bg-layer)
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "area-brush")))
			(gimp-selection-invert img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(plug-in-hsv-noise (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 2 5 8 8)
			(gimp-layer-set-name varDupLayer "layer 1")
		)

		(gimp-image-set-active-layer img bg-layer)

		;; 
		;; ************************************************************************************************************************************
		(gimp-image-insert-layer img fill-layer 0 -1)
		(gimp-image-set-active-layer img fill-layer)
		(gimp-context-set-foreground inBgColor)
		(gimp-edit-fill fill-layer FOREGROUND-FILL)

		;;
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer 1")) FALSE)
			(gimp-layer-set-name varDupLayer "layer 1 copy")
		)

		;;
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "sci-fi-brush")))
			(gimp-selection-invert img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(gimp-layer-set-name varDupLayer "layer 2")
		)

		;; 
		;; ************************************************************************************************************************************
		;; 
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 2")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
				(hexagon-count 0)
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer 2")) FALSE)
			(plug-in-autocrop-layer (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer)
			(gimp-selection-all img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			;;
			(gimp-context-set-pattern "Hexagons big (seamless)")
			(gimp-drawable-fill varDupLayer PATTERN-FILL)
			(gimp-context-set-feather 0)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "sci-fi-brush")))
			(gimp-selection-invert img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(gimp-item-set-visible varDupLayer FALSE)
			(gimp-layer-set-name varDupLayer "layer 2 copy")
		)

		;;
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-context-set-feather 0)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer 2 copy")))
			(gimp-selection-invert img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(gimp-layer-set-name varDupLayer "layer 3")
		)

		;; 
		;; ************************************************************************************************************************************
		;; 
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 2")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
				(hexagon-count 0)
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-item-set-visible varDupLayer TRUE)
			(plug-in-autocrop-layer RUN-NONINTERACTIVE img varDupLayer)
			(gimp-selection-all img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			;;
			(set! owidth (- (car (gimp-drawable-width varDupLayer)) 20))
			(set! oheight (- (car (gimp-drawable-height varDupLayer)) 20))
			(gimp-context-set-brush "Hexagon Sci-Fi -brush")
			(gimp-brush-set-hardness "Hexagon Sci-Fi -brush" 1)
			(gimp-context-set-dynamics "Sci-Fi -dynamic")
			(while (<= hexagon-count (+ inAmount 30))
				(let* (
						(segment (cons-array 4 'double))  
						(xa (rand owidth ))
						(ya (rand oheight ))
					)
					(aset segment 0 (* 1 xa))
					(aset segment 1 (* 1 ya))
					(aset segment 2 (* 1 xa))
					(aset segment 3 (* 1 ya))
					(gimp-context-set-brush-size (+ 30 (rand 55)))
					(gimp-brush-set-radius "Hexagon Sci-Fi -brush" (+ 25 (rand 30)))
					(gimp-brush-set-spacing "Hexagon Sci-Fi -brush" 100)
					(gimp-brush-set-angle "Hexagon Sci-Fi -brush" (/ (* (* (rand 360) 2) 3.1415) 360))
					(gimp-paintbrush-default varDupLayer npoint segment)
					(set! hexagon-count (+ hexagon-count 1))
				);
			);

			(gimp-context-set-feather 0)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "sci-fi-brush")))
			(gimp-selection-invert img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(gimp-layer-set-name varDupLayer "layer 2 copy 2")
			(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer 2 copy 2")) FALSE)
		)

		;;
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-name varDupLayer "layer 4")
			(gimp-context-set-feather 0)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer 2 copy 2")))
			(gimp-selection-invert img)
			(gimp-edit-clear (car (gimp-image-get-layer-by-name img "layer 4")))
			(gimp-selection-none img)
			(gimp-brightness-contrast (car (gimp-image-get-layer-by-name img "layer 4")) -60 0)
			(gimp-hue-saturation (car (gimp-image-get-layer-by-name img "layer 4")) ALL-HUES 0 -6 0)
		)

		;; 
		;; ************************************************************************************************************************************
		;; 
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 2")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
				(hexagon-count 0)
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-item-set-visible varDupLayer TRUE)
			(plug-in-autocrop-layer (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer)
			(gimp-selection-all img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			;
			(set! owidth (- (car (gimp-drawable-width varDupLayer)) 10))
			(set! oheight (- (car (gimp-drawable-height varDupLayer)) 10))
			(gimp-context-set-brush "Hexagon Sci-Fi -brush")
			(gimp-brush-set-hardness "Hexagon Sci-Fi -brush" 1)
			(while (<= hexagon-count (+ inAmount 45))
				(let* (
						(segment (cons-array 4 'double))  
						(xa (rand owidth ))
						(ya (rand oheight ))
					)
					(aset segment 0 (* 1 xa))
					(aset segment 1 (* 1 ya))
					(aset segment 2 (* 1 xa))
					(aset segment 3 (* 1 ya))
					(gimp-context-set-brush-size (+ 15 (rand 60)))
					(gimp-brush-set-radius "Hexagon Sci-Fi -brush" (+ 25 (rand 40)))
					(gimp-brush-set-angle "Hexagon Sci-Fi -brush" (/ (* (* (rand 360) 2) 3.1415) 360))
					(gimp-paintbrush-default varDupLayer npoint segment)
					(set! hexagon-count (+ hexagon-count 1))
				);
			);

			(gimp-context-set-feather 0)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "sci-fi-brush")))
			(gimp-selection-invert img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(gimp-layer-set-name varDupLayer "layer 2 copy 3")
			(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer 2 copy 3")) FALSE)
		)

		;;
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-context-set-feather 0)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer 2 copy 3")))
			(gimp-selection-invert img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(gimp-brightness-contrast varDupLayer -120 0)
			(gimp-hue-saturation varDupLayer ALL-HUES 0 -12 0)
			(gimp-layer-set-name varDupLayer "hexagon particles #5")
		)

		;;
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 3")))
		(gimp-image-insert-layer img path-layer 0 -1)
		(gimp-context-set-feather 6)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "sci-fi-brush")))
		(plug-in-sel2path RUN-NONINTERACTIVE img path-layer)
		(gimp-selection-none img)

		;;
		(gimp-context-set-brush "Hexagon Sci-Fi -brush")
		(gimp-context-set-brush-size (+ 100 (rand 45)))
		(gimp-context-set-dynamics "Sci-Fi -dynamic")

		;;
		;;
		(gimp-context-set-paint-method "gimp-paintbrush")
		(set! vector-path (car (gimp-image-get-active-vectors img)))
		(gimp-edit-stroke-vectors path-layer vector-path)
		(gimp-image-remove-vectors img vector-path)

		;;
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-name varDupLayer "layer 7")
			(gimp-context-set-feather 0)
			(gimp-selection-layer-alpha path-layer)
			(gimp-selection-invert img)
			(gimp-edit-clear (car (gimp-image-get-layer-by-name img "layer 7")))
			(gimp-selection-none img)
			(gimp-item-set-visible path-layer FALSE)
		)


		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy")))
		(gimp-context-set-feather 0)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "sci-fi-brush")))
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "layer 1 copy")))
		(gimp-selection-none img)

		;;
		;; *************************************************************************************************************************************
			;; 
			(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1")))
			(let* (
					(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
				)
				(gimp-image-insert-layer img varDupLayer 0 -1)
				(gimp-item-set-visible varDupLayer TRUE)
				(gimp-layer-translate varDupLayer -69 1)
				(gimp-layer-set-name varDupLayer "layer 1 copy 2")
			)

			;; 
			(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy 2")))
			(let* (
					(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 1")) 1)))
				)
				(gimp-image-insert-layer img varDupLayer 0 -1)
				(gimp-item-set-visible varDupLayer TRUE)
				(gimp-layer-set-name varDupLayer "layer 1 copy 3")
			)

			;; 
			(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy 2")))
			(let* (
					(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 1 copy 2")) 1)))
				)
				(gimp-image-insert-layer img varDupLayer 0 -1)
				(gimp-layer-translate varDupLayer 14 -54)
				(gimp-layer-set-name varDupLayer "layer 1 copy 4")
			)

			;; 
			(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy 4")))
			(let* (
					(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 1 copy 4")) 1)))
				)
				(gimp-image-insert-layer img varDupLayer 0 -1)
				(gimp-layer-translate varDupLayer 80 -44)
				(gimp-layer-set-name varDupLayer "layer 1 copy 5")
			)

			;;
			(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy 5")))
			(let* (
					(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 1 copy 5")) 1)))
				)
				(gimp-image-insert-layer img varDupLayer 0 -1)
				(gimp-layer-translate varDupLayer 86 44)
				(gimp-layer-set-name varDupLayer "layer 1 copy 6")
			)

			;;
			(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy 6")))
			(let* (
					(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 1 copy 6")) 1)))
				)
				(gimp-image-insert-layer img varDupLayer 0 -1)
				(gimp-layer-translate varDupLayer 18 98)
				(gimp-layer-set-name varDupLayer "object part (without particles) #1")
			)

			;;
			(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object part (without particles) #1")))
			(let* (
					(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object part (without particles) #1")) 1)))
				)
				(gimp-image-insert-layer img varDupLayer 0 -1)
				(gimp-layer-translate varDupLayer -63 72)
				(gimp-layer-set-name varDupLayer "layer 1 copy 8")
			)

			;; 
			(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy 8")))
			(let* (
					(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 1 copy 8")) 1)))
				)
				(gimp-image-insert-layer img varDupLayer 0 -1)
				(gimp-layer-translate varDupLayer -155 23)
				(gimp-layer-set-name varDupLayer "layer 1 copy 9")
			)
			
			;; 
			(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy 9")))
			(let* (
					(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 1 copy 9")) 1)))
				)
				(gimp-image-insert-layer img varDupLayer 0 -1)
				(gimp-layer-translate varDupLayer 50 -64)
				(gimp-layer-set-name varDupLayer "layer 1 copy 10")
			)

			;; 
			(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy 10")))
			(let* (
					(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 1 copy 10")) 1)))
				)
				(gimp-image-insert-layer img varDupLayer 0 -1)
				(gimp-layer-translate varDupLayer 39 -71)
				(gimp-layer-set-name varDupLayer "layer 1 copy 11")
			)

			;; 
			(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy 11")))
			(let* (
					(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 1 copy 11")) 1)))
				)
				(gimp-image-insert-layer img varDupLayer 0 -1)
				(gimp-layer-translate varDupLayer 66 41)
				(gimp-layer-set-name varDupLayer "layer 1 copy 12")
			)

			;;
			(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy 12")))
			(let* (
					(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 1 copy 12")) 1)))
				)
				(gimp-image-insert-layer img varDupLayer 0 -1)
				(gimp-layer-translate varDupLayer -61 77)
				(gimp-layer-set-name varDupLayer "layer 1 copy 13")
			)


			;;
			(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer 1 copy")) FALSE)
			(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer 7")) FALSE)
			(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "hexagon particles #5")) FALSE)
			(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer 4")) FALSE)
			(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer 3")) FALSE)
			(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "background-color")) FALSE)
			(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "background")) FALSE)

			(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy 3")))

			(gimp-image-merge-visible-layers img CLIP-TO-BOTTOM-LAYER)

			(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "layer 1 copy 2")))
			(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "layer 1 copy 2")) 8 8 1)
			(plug-in-hsv-noise (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "layer 1 copy 2")) 2 5 8 8)
		;; 

		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer 2")))
		(gimp-selection-invert img)
		(gimp-selection-grow img 6)
		(gimp-selection-invert img)

		;; 
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 3")))
		(gimp-image-insert-layer img path-layer2 0 -1)
		(plug-in-sel2path RUN-NONINTERACTIVE img path-layer2)
		(gimp-selection-none img)

		(gimp-context-set-brush "Hexagon Sci-Fi -brush")
		(gimp-context-set-brush-size (+ 40 (rand 12)))
		(gimp-brush-set-spacing "Hexagon Sci-Fi -brush" (+ 110 (rand 40)))
		(gimp-context-set-dynamics "Sci-Fi -dynamic")

		;;
		;; 
		(gimp-context-set-paint-method "gimp-paintbrush")
		(set! vector-path (car (gimp-image-get-active-vectors img)))
		(gimp-edit-stroke-vectors path-layer2 vector-path)

		;;
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 3")))
		(gimp-image-insert-layer img path-layer3 0 -1)

		(gimp-context-set-brush-size (+ 30 (rand 20)))
		(gimp-context-set-dynamics "Sci-Fi -dynamic")

		(gimp-context-set-paint-method "gimp-paintbrush")
		(set! vector-path (car (gimp-image-get-active-vectors img)))
		(gimp-edit-stroke-vectors path-layer3 vector-path)
		(gimp-vectors-set-name vector-path "path-layer3")


		;;
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 3")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 1 copy 2")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-name varDupLayer "layer 11")
			(gimp-context-set-feather 0)
			(gimp-selection-layer-alpha path-layer3)
			(gimp-selection-invert img)
			(gimp-edit-clear (car (gimp-image-get-layer-by-name img "layer 11")))
			(gimp-selection-none img)
			(gimp-item-set-visible path-layer3 FALSE)
		)

		;;
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 3")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 1 copy 2")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-name varDupLayer "layer 12")
			(gimp-context-set-feather 0)
			(gimp-selection-layer-alpha path-layer2)
			(gimp-selection-invert img)
			(gimp-edit-clear (car (gimp-image-get-layer-by-name img "layer 12")))
			(gimp-selection-none img)
			(gimp-item-set-visible path-layer2 FALSE)
		)

		;;
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer 1 copy 2")) FALSE)


		;; 
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 1")) 1)))
				(hexagon-count 0)
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-item-set-visible varDupLayer TRUE)
			(gimp-context-set-feather 0)
			(gimp-selection-all img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			;; 
			(gimp-context-set-brush "Hexagon Sci-Fi -brush")
			(gimp-context-set-dynamics "Sci-Fi -dynamic")
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer 1")))

			;;
			(set! owidth (- (car (gimp-drawable-width varDupLayer)) 10))
			(set! oheight (- (car (gimp-drawable-height varDupLayer)) 10))
			(gimp-context-set-brush "Hexagon Sci-Fi -brush")
			(gimp-brush-set-hardness "Hexagon Sci-Fi -brush" 1)
			(while (<= hexagon-count (* 10 inAmount))
				(let* (
						(segment (cons-array 4 'double))  
						(xa (rand owidth ))
						(ya (rand oheight ))
					)
					(aset segment 0 (* 1 xa))
					(aset segment 1 (* 1 ya))
					(aset segment 2 (* 1 xa))
					(aset segment 3 (* 1 ya))
					(gimp-context-set-brush-size (+ 35 (rand 80)) )
					(gimp-brush-set-angle "Hexagon Sci-Fi -brush" (/ (* (* (rand 360) 2) 3.1415) 360))
					(gimp-paintbrush-default varDupLayer npoint segment)
					(set! hexagon-count (+ hexagon-count 1))
				);
			);

			(gimp-layer-set-name varDupLayer "layer 1 copy 2(b)")
			(gimp-selection-none img)
			;; 
			;; *********************************************************************************************************
				(python-layer-fx-color-overlay (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "layer 1 copy 2(b)")) inScFiColor 100 NORMAL-MODE TRUE)
		)

		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "background-color")) TRUE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "hexagon particles #5")) TRUE)

		;; 
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy 2(b)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 1 copy 2(b)")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 6 6 1)
			(gimp-layer-set-name varDupLayer "layer 1 copy 4")
		)

		;; 
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy 4")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 1 copy 4")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 8 8 1)
			(gimp-layer-set-name varDupLayer "Layer 1 copy 5")
		)

		(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "Layer 1 copy 5")) CLIP-TO-BOTTOM-LAYER)
		;; 
		(gimp-image-raise-item img (car (gimp-image-get-layer-by-name img "layer 1 copy")))
		(gimp-image-raise-item img (car (gimp-image-get-layer-by-name img "layer 1 copy")))
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer 1 copy")) TRUE)

		(gimp-image-raise-item img (car (gimp-image-get-layer-by-name img "layer 1 copy 4")))
		(gimp-image-raise-item img (car (gimp-image-get-layer-by-name img "layer 1 copy 4")))
		(gimp-image-raise-item img (car (gimp-image-get-layer-by-name img "layer 1 copy 4")))
		(gimp-image-raise-item img (car (gimp-image-get-layer-by-name img "layer 1 copy 2(b)")))
		(gimp-image-raise-item img (car (gimp-image-get-layer-by-name img "layer 1 copy 2(b)")))
		(gimp-image-raise-item img (car (gimp-image-get-layer-by-name img "layer 1 copy 2(b)")))

		(gimp-image-raise-item img (car (gimp-image-get-layer-by-name img "layer 7")))
		(gimp-image-raise-item img (car (gimp-image-get-layer-by-name img "layer 7")))
		(gimp-image-raise-item img (car (gimp-image-get-layer-by-name img "layer 7")))
		(gimp-image-raise-item img (car (gimp-image-get-layer-by-name img "layer 7")))
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer 7")) TRUE)

		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer 4")) TRUE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer 3")) TRUE)

		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "layer 1 copy 2(b)")) SCREEN-MODE)


		;; 
		;; *********************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "area-brush")))
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "area-brush")) TRUE)
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "area-brush")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-resize-to-image-size varDupLayer)
			(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 100 100 1)
			(gimp-layer-set-name varDupLayer "area-brush copy 4")
			(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "area-brush")) FALSE)
		)

		(let (
				(layers (repeat (lambda () (my-duplicate-layer img (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "area-brush copy 4")) 0))))
					(- 4 1)))
			)
		)

		;; 
		(if (= inGradientName 0);;
			(begin
				(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "area-brush copy 4 copy #2")) CLIP-TO-BOTTOM-LAYER)
				(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "area-brush copy 4 copy #1")) CLIP-TO-BOTTOM-LAYER)
				(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "area-brush copy 4 copy")) CLIP-TO-BOTTOM-LAYER)
			)
		)

		;;
		(if (= inGradientName 1);;
			(begin
				(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "area-brush copy 4-Kopie #2")) CLIP-TO-BOTTOM-LAYER)
				(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "area-brush copy 4-Kopie #1")) CLIP-TO-BOTTOM-LAYER)
				(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "area-brush copy 4-Kopie")) CLIP-TO-BOTTOM-LAYER)
			)
		)

		(gimp-context-set-feather 10)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "area-brush copy 4")))
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "area-brush copy 4")))
		(gimp-selection-none img)
		(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "area-brush copy 4")) 50 50 1)

		(let (
				(layers (repeat (lambda () (my-duplicate-layer img (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "area-brush copy 4")) 0))))
					(- 5 1)))
			)
		)

		;; 
		(if (= inGradientName 0);;
			(begin
				(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "area-brush copy 4 copy #3")) CLIP-TO-BOTTOM-LAYER)
				(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "area-brush copy 4 copy #2")) CLIP-TO-BOTTOM-LAYER)
				(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "area-brush copy 4 copy #1")) CLIP-TO-BOTTOM-LAYER)
				(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "area-brush copy 4 copy")) CLIP-TO-BOTTOM-LAYER)
			)
		)

		;; 
		(if (= inGradientName 1);;
			(begin
				(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "area-brush copy 4-Kopie #3")) CLIP-TO-BOTTOM-LAYER)
				(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "area-brush copy 4-Kopie #2")) CLIP-TO-BOTTOM-LAYER)
				(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "area-brush copy 4-Kopie #1")) CLIP-TO-BOTTOM-LAYER)
				(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "area-brush copy 4-Kopie")) CLIP-TO-BOTTOM-LAYER)
			)
		)

		(gimp-context-set-feather 15)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "area-brush")))
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "area-brush copy 4")))
		(gimp-selection-none img)

		(gimp-context-set-feather 5)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "area-brush copy 4")))
		(gimp-selection-grow img 10)
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "layer 1 copy 4")))
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "layer 1 copy 4")))
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "layer 1 copy 2(b)")))
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "layer 1 copy 2(b)")))
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "area-brush copy 4")) FALSE)
		(gimp-selection-none img)

		(gimp-context-set-feather 10)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "sci-fi-brush")))
		(gimp-selection-grow img 15)
		(gimp-selection-invert img)
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "layer 1 copy 4")))
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "layer 1 copy 2(b)")))
		(gimp-selection-none img)
		;; 
		;; *********************************************************************************************************
			(python-layer-fx-outer-glow (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "layer 1 copy 4")) inScFiColor 14 7 2 SCREEN-MODE 50 4 TRUE TRUE)
		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "layer 1 copy 4")) SCREEN-MODE)

		;; 
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "background-color")))
		(gimp-image-insert-layer img gradient-layer-radial 0 -1)
		(gimp-context-set-foreground '(255 255 255))
		(gimp-edit-fill gradient-layer-radial WHITE-FILL) ;; 

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
				(python-layerfx-gradient-overlay RUN-NONINTERACTIVE img gradient-layer-radial (if (= inGradientName 0) "FG to Transparent" (if (= inGradientName 1) "VG nach Transparent")) GRADIENT-RADIAL REPEAT-NONE FALSE 100 NORMAL-MODE (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)) 0 (- ImageWidth (/ ImageWidth 4)) FALSE)
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "gradient-fill")))
			(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "gradient-fill-gradient")) 30 30 1)
			(gimp-layer-scale (car (gimp-image-get-layer-by-name img "gradient-fill-gradient")) (* ImageWidth 1.7) (* ImageHeight 1.7) TRUE)
			(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "gradient-fill-gradient")))
			(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "gradient-fill-gradient")) 16)
		)


		;; 
		;; *******************************************************************************************************************************************
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer 1")) TRUE)
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1")))
		(gimp-item-set-name sci-fi-layer-group "Abstract bg brush")
		(gimp-layer-set-mode sci-fi-layer-group NORMAL-MODE)
		(gimp-layer-set-opacity sci-fi-layer-group 100)
		(gimp-image-insert-layer img sci-fi-layer-group 0 -1)

		;; 
		(gimp-image-insert-layer img sci-fi-layer sci-fi-layer-group -1)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer 1")) FALSE)


		;;
		;; *******************************************************************************************************************************************
			(gimp-context-set-foreground inBgColor)
			(set! owidth (- (car (gimp-drawable-width sci-fi-layer)) 80))
			(set! oheight (- (car (gimp-drawable-height sci-fi-layer)) 80))
			(gimp-context-set-brush inUserBrush)
			(while (<= smoke-count 66)
				(let* (
						(segment (cons-array 4 'double))  
						(xa (rand owidth ))
						(ya (rand oheight ))
					)
					(aset segment 0 (* 1 xa))
					(aset segment 1 (* 1 ya))
					(aset segment 2 (* 1 xa))
					(aset segment 3 (* 1 ya))
					(gimp-context-set-brush-size (+ 500 (rand 1000)) )
					(gimp-paintbrush-default sci-fi-layer npoint segment)
					(set! smoke-count (+ smoke-count 1))
				);; 
			);; 


		(gimp-image-set-active-layer img sci-fi-layer)
		(gimp-image-insert-layer img sci-fi-layer2 0 -1)
		(gimp-context-set-feather 4)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "area-brush")))
		(plug-in-sel2path RUN-NONINTERACTIVE img sci-fi-layer2)
		(gimp-selection-none img)

		;;
		(gimp-context-set-brush inUserBrush)
		(gimp-context-set-brush-size (+ 350 (rand 1000)) )
		(gimp-context-set-dynamics "Sci-Fi -dynamic")

		;;
		;;
		(gimp-context-set-paint-method "gimp-paintbrush")
		(set! vector-path (car (gimp-image-get-active-vectors img)))
		(gimp-edit-stroke-vectors sci-fi-layer2 vector-path)
		(gimp-image-remove-vectors img vector-path)


		(gimp-image-set-active-layer img sci-fi-layer2)
		(gimp-image-insert-layer img sci-fi-layer3 0 -1)
		;; 
		;; *******************************************************************************************************************************************
			;; 
			(set! owidth (- (car (gimp-drawable-width sci-fi-layer3)) 100))
			(set! oheight (- (car (gimp-drawable-height sci-fi-layer3)) 100))
			(gimp-context-set-brush inUserBrush)
			(while (<= smoke-count3 (+ 40 (rand 70)))
				(let* (
						(segment (cons-array 4 'double))  
						(xa (rand owidth ))
						(ya (rand oheight ))
					)
					(aset segment 0 (* 1 xa))
					(aset segment 1 (* 1 ya))
					(aset segment 2 (* 1 xa))
					(aset segment 3 (* 1 ya))
					(gimp-context-set-brush-size (+ 400 (rand 1000)) )
					(gimp-paintbrush-default sci-fi-layer3 npoint segment)
					(set! smoke-count3 (+ smoke-count3 1))
				);;
			);;


		(gimp-image-set-active-layer img sci-fi-layer2)
		(gimp-image-insert-layer img sci-fi-layer4 0 -1)
		(gimp-context-set-foreground '(255 255 255))
		;; 
		;; *******************************************************************************************************************************************
		(gimp-context-set-feather 20)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "area-brush")))
		(plug-in-sel2path RUN-NONINTERACTIVE img sci-fi-layer4)
		(gimp-selection-none img)

		;; 
		(gimp-context-set-brush inUserBrush)
		(gimp-context-set-brush-size (+ 350 (rand 800)) )
		(gimp-context-set-dynamics "Sci-Fi -dynamic")

		;; 
		;; 
		(gimp-context-set-paint-method "gimp-paintbrush")
		(set! vector-path (car (gimp-image-get-active-vectors img)))
		(gimp-edit-stroke-vectors sci-fi-layer4 vector-path)
		(gimp-image-remove-vectors img vector-path)
		(set! seed (if (number? seed) seed (realtime)))
		(plug-in-rgb-noise (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img sci-fi-layer4 TRUE FALSE 0.3 0.3 0.3 0)
		(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img sci-fi-layer4 2.8 2.8 1)

		;; 
		;; *******************************************************************************************************************************************
		(gimp-image-set-active-layer img sci-fi-layer)
		(gimp-image-insert-layer img sci-fi-layer5 0 -1)
		(gimp-context-set-feather 10)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "area-brush")))
		(plug-in-sel2path RUN-NONINTERACTIVE img sci-fi-layer5)
		(gimp-selection-none img)

		;; 
		(gimp-context-set-brush inUserBrush)
		(gimp-context-set-brush-size (+ 450 (rand 1000)) )
		(gimp-context-set-dynamics "Sci-Fi -dynamic")

		;; 
		;; 
		(gimp-context-set-paint-method "gimp-paintbrush")
		(set! vector-path (car (gimp-image-get-active-vectors img)))
		(gimp-edit-stroke-vectors sci-fi-layer5 vector-path)
		(gimp-image-remove-vectors img vector-path)


		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 11")))
		(gimp-image-insert-layer img sci-fi-layer6 0 -1)
		(gimp-context-set-foreground inBgColor)
		;; 
		;; *******************************************************************************************************************************************
		;; 
		;; 
		(gimp-context-set-defaults)
		(gimp-context-set-brush inUserBrushOpacity)
		(gimp-context-set-brush-size (+ 280 (rand 400)) )
		(gimp-context-set-dynamics "Sci-Fi -dynamic")

		;; 
		;; 
		(gimp-context-set-paint-method "gimp-paintbrush")
		(set! vector-path (car (gimp-image-get-vectors-by-name img "path-layer3")))
		(gimp-edit-stroke-vectors sci-fi-layer6 vector-path)
		;; 
		;; *********************************************************************************************************
			(python-layer-fx-color-overlay (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img sci-fi-layer6 inScFiInsideGlowColor 100 NORMAL-MODE TRUE)
			(python-layer-fx-outer-glow (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "hexagon particles glow (outside)")) inScFiInsideGlowColor 24 7 3 NORMAL-MODE 80 7 TRUE TRUE)
		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "hexagon particles glow (outside)")) SCREEN-MODE)
		(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "hexagon particles glow (outside)")) 80)


		;; 
		(plug-in-rgb-noise (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "layer 3")) TRUE TRUE 0.04 0.04 0.04 0)


		;; 
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "hexagon particles glow (outside)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 1 copy 2(b)")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-context-set-feather 0)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "sci-fi-brush")))
			(gimp-selection-invert img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer 11")))
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer 12")))
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer 3")))
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer 7")))
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer 1 copy")))
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 9 9 1)
			(gimp-layer-set-name varDupLayer "layer 1 copy 4(b)")
		)

		;;
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy 4(b)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 1 copy 4(b)")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-context-set-feather 0)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer 4")))
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 4 4 1)
			(gimp-layer-set-name varDupLayer "layer 1 copy 6")
		)

		;; 
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy 6")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 1 copy 6")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 55 55 1)
			(gimp-layer-set-mode varDupLayer SCREEN-MODE)
			(gimp-layer-set-name varDupLayer "layer 1 copy 6(b)")
		)

		;; 
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy 6")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 1 copy 6")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 45 45 1)
			(gimp-layer-set-mode varDupLayer SCREEN-MODE)
			(gimp-layer-set-name varDupLayer "layer 1 copy 7 (13)")
		)


		;;
		;; *******************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "area-brush")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-resize-to-image-size varDupLayer)
			(gimp-context-set-foreground '(0 0 0))
			(gimp-context-set-feather 2)
			(gimp-selection-layer-alpha varDupLayer)
			(gimp-edit-fill varDupLayer FOREGROUND-FILL)
			(gimp-selection-invert img)
			(gimp-edit-clear varDupLayer)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(gimp-hue-saturation varDupLayer ALL-HUES 0 -100 0)
			(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 44 44 1)
			(gimp-item-set-visible varDupLayer TRUE)
			(gimp-layer-set-name varDupLayer "object shadow")
		)

		;; 
		;; *******************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy 4")))
		(gimp-image-insert-layer img sci-fi-layer7 0 -1)

		;; 
		(gimp-context-set-foreground inBgColor)
		(gimp-context-set-brush "Sci-Fi Brush (mash, hexagons)")
		(gimp-context-set-brush-size (+ 750 (rand 1250)) )
		(gimp-context-set-dynamics "Sci-Fi -dynamic")

		;; 
		;;
		(gimp-context-set-paint-method "gimp-paintbrush")
		(set! vector-path (car (gimp-image-get-vectors-by-name img "path-layer3")))
		(gimp-edit-stroke-vectors sci-fi-layer7 vector-path)
		(gimp-context-set-feather 1)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "area-brush")))
		(gimp-selection-invert img)
		(gimp-edit-clear sci-fi-layer7)
		(gimp-edit-clear sci-fi-layer7)
		(gimp-edit-clear sci-fi-layer7)
		(gimp-selection-none img)
		;; 
		;; *********************************************************************************************************
			(python-layer-fx-color-overlay (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img sci-fi-layer7 inScFiInsideColor 100 NORMAL-MODE TRUE)

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "abstract web (inside)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "abstract web (inside)")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-name varDupLayer "layer 19 smooth")
			;; 
			;; *********************************************************************************************************
				(python-layer-fx-outer-glow (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "layer 19 smooth")) inScFiInsideGlowColor 70 5 12 SCREEN-MODE 70 30 TRUE TRUE)
			(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "layer 19 smooth")) 5 5 1)
			(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "layer 19 smooth")) CLIP-TO-BOTTOM-LAYER)
		)

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "abstract web (inside)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "abstract web (inside)")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-image-merge-down img varDupLayer CLIP-TO-BOTTOM-LAYER)
		)

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "abstract web (inside)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "abstract web (inside)")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 6 6 1)
			(gimp-image-merge-down img varDupLayer CLIP-TO-BOTTOM-LAYER)
		)

		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "abstract web (inside)")) SCREEN-MODE)


		;; 
		;; *******************************************************************************************************************************************
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer 1")) TRUE)
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1")))
		(gimp-image-insert-layer img sci-fi-layer8 0 -1)

		;; 
		(gimp-context-set-brush "Sci-Fi Brush (mash)")
		(gimp-context-set-brush-size (+ 800 (rand 1150)) )
		(gimp-context-set-dynamics "Sci-Fi -dynamic")

		;;
		;; 
		(gimp-context-set-paint-method "gimp-paintbrush")
		(set! vector-path (car (gimp-image-get-vectors-by-name img "path-layer3")))
		(gimp-edit-stroke-vectors sci-fi-layer8 vector-path)
		;; 
		;; *********************************************************************************************************
			(python-layer-fx-color-overlay (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img sci-fi-layer8 inScFiColor 100 NORMAL-MODE TRUE)

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "abstract web (outside)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "abstract web (outside)")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 6.5 6.5 1)
			(gimp-layer-set-name varDupLayer "abstract web glow (outside)")
		)

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "abstract web glow (outside)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "abstract web glow (outside)")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-image-merge-down img varDupLayer CLIP-TO-BOTTOM-LAYER)
		)

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "abstract web glow (outside)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "abstract web glow (outside)")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-image-merge-down img varDupLayer CLIP-TO-BOTTOM-LAYER)
		)


		;;
		;; *******************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1")))
		(gimp-image-insert-layer img sci-fi-layer9 0 -1)

		(gimp-context-set-feather 10)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "area-brush")))
		(plug-in-sel2path RUN-NONINTERACTIVE img sci-fi-layer9)
		(gimp-selection-none img)

		;; 
		(gimp-context-set-brush "scfi TechBrush -Smoke glow")
		(gimp-context-set-brush-size (+ 980 (rand 350)))
		(gimp-context-set-dynamics "Sci-Fi -dynamic")

		;;
		;;
		(gimp-context-set-paint-method "gimp-paintbrush")
		(set! vector-path (car (gimp-image-get-active-vectors img)))
		(gimp-edit-stroke-vectors sci-fi-layer9 vector-path)
		(gimp-image-remove-vectors img vector-path)

		(gimp-context-set-feather 5)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "abstract bg #5 (dark)")))
		(gimp-edit-clear sci-fi-layer9)
		(gimp-selection-none img)
		;;
		;; *********************************************************************************************************
			(python-layer-fx-color-overlay (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img sci-fi-layer9 inScFiColor 100 NORMAL-MODE TRUE)

		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "object light")) SCREEN-MODE)
		(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "object light")) 45)

		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer 1")) FALSE)


		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 1 copy")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-name varDupLayer "object part (without particles) #1")
		)

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object part (without particles) #1")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object part (without particles) #1")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-image-merge-down img varDupLayer CLIP-TO-BOTTOM-LAYER)
		)


		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy")))
		(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "layer 1 copy")) 13.5 13.5 1)

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 1 copy")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 74.5 74.5 1)
			(gimp-image-merge-down img varDupLayer CLIP-TO-BOTTOM-LAYER)
		)

		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "layer 1 copy")) DODGE-MODE)
		(gimp-layer-set-name (car (gimp-image-get-layer-by-name img "layer 1 copy")) "object light 1")

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object light 1")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object light 1")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 15.5 15.5 1)
			(gimp-layer-set-name varDupLayer "object light 2")
		)

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object light 2")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object light 2")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-image-merge-down img varDupLayer CLIP-TO-BOTTOM-LAYER)
		)
		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "object light 2")) SCREEN-MODE)


		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object part (without particles) #1")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object light 2")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "object part (without particles) #1")))
			(gimp-selection-invert img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(gimp-layer-set-name varDupLayer "layer 1 copy 10")
		)

		(gimp-image-lower-item img (car (gimp-image-get-layer-by-name img "layer 4")))

		;;
		;; *******************************************************************************************************************************************
			(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object part (without particles) #1")))
			(let* (
					(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object part (without particles) #1")) 1)))
				)
				(gimp-image-insert-layer img varDupLayer 0 -1)
				(gimp-layer-set-mode varDupLayer DODGE-MODE)
				(gimp-layer-set-opacity varDupLayer 29)
				(gimp-layer-set-name varDupLayer "object part (without particles) (dodge mode)")
			)

			(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 7")))
			(let* (
					(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 7")) 1)))
				)
				(gimp-image-insert-layer img varDupLayer 0 -1)
				(gimp-layer-set-mode varDupLayer DODGE-MODE)
				(gimp-layer-set-opacity varDupLayer 29)
				(gimp-layer-set-name varDupLayer "hexagon particles #7 (dodge mode)")
			)

			(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 3")))
			(let* (
					(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 3")) 1)))
				)
				(gimp-image-insert-layer img varDupLayer 0 -1)
				(gimp-layer-set-mode varDupLayer DODGE-MODE)
				(gimp-layer-set-opacity varDupLayer 29)
				(gimp-layer-set-name varDupLayer "hexagon particles #8 (main, dodge mode)")
			)

			(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 12")))
			(let* (
					(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 12")) 1)))
				)
				(gimp-image-insert-layer img varDupLayer 0 -1)
				(gimp-layer-set-mode varDupLayer DODGE-MODE)
				(gimp-layer-set-opacity varDupLayer 29)
				(gimp-layer-set-name varDupLayer "hexagon particles #2 (dodge mode)")
			)

			(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer 11")))
			(let* (
					(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer 11")) 1)))
				)
				(gimp-image-insert-layer img varDupLayer 0 -1)
				(gimp-layer-set-mode varDupLayer DODGE-MODE)
				(gimp-layer-set-opacity varDupLayer 29)
				(gimp-layer-set-name varDupLayer "hexagon particles #1 (dodge)")
			)
		;;

		(gimp-context-set-feather 15)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "area-brush")))
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "object light 1")))
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "layer 1 copy 10")))
		(gimp-selection-none img)
		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "layer 1 copy 10")) SCREEN-MODE)
		(gimp-layer-set-name (car (gimp-image-get-layer-by-name img "layer 1 copy 10")) "light on object")

		;; 
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "abstract web glow (outside)")))
		(gimp-image-insert-layer img sci-fi-layer10 0 -1)

		;;
		(gimp-context-set-brush "Sci-Fi Brush (border, mash)")
		(gimp-context-set-brush-size (+ 350 (rand 650)) )
		(gimp-context-set-dynamics "Sci-Fi -dynamic")

		;;
		;;
		(gimp-context-set-paint-method "gimp-paintbrush")
		(set! vector-path (car (gimp-image-get-vectors-by-name img "path-layer3")))
		(gimp-edit-stroke-vectors sci-fi-layer10 vector-path)
		;; 
		;; *********************************************************************************************************
			(python-layer-fx-color-overlay (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img sci-fi-layer10 inScFiColor 100 NORMAL-MODE TRUE)

		(gimp-context-set-feather 15)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "area-brush")))
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "hexagons web (border)")))
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "hexagons web (border)")))
		(gimp-selection-none img)

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "hexagons web (border)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "hexagons web (border)")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 6.5 6.5 1)
			(gimp-layer-set-name varDupLayer "hexagons web (border) glow")
		)


		;; 
		;; *******************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object shadow")))

		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "area-brush")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-resize-to-image-size varDupLayer)
			(gimp-edit-clear varDupLayer)
			(gimp-item-set-visible varDupLayer TRUE)
			(gimp-layer-set-name varDupLayer "abstract circle")
		)

		(gimp-context-set-foreground '(0 0 0))
			;; 
			(gimp-context-set-paint-method "gimp-paintbrush")
			(gimp-context-set-brush inUserBrushCircle)
			(gimp-context-set-brush-size (+ 980 (rand 250)))
			(set! owidth (/ (car (gimp-drawable-width (car (gimp-image-get-layer-by-name img "area-brush")))) 2))
			(set! oheight (/ (car (gimp-drawable-height (car (gimp-image-get-layer-by-name img "area-brush")))) 2))
			(while (<= ornament-count 0)
				(let* (
						(segment (cons-array 4 'double))  
						(xa owidth)
						(ya oheight)
					)
					(aset segment 0 (* 1 xa))
					(aset segment 1 (* 1 ya))
					(aset segment 2 (* 1 xa))
					(aset segment 3 (* 1 ya))
					(gimp-paintbrush-default (car (gimp-image-get-layer-by-name img "abstract circle")) npoint segment)
					(set! ornament-count (+ ornament-count 1))
				);; 
			);; 
		;; 
		;; *********************************************************************************************************
			(python-layer-fx-color-overlay (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "abstract circle")) inScFiColor 100 NORMAL-MODE TRUE)

		(plug-in-autocrop-layer RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "abstract circle")))

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "abstract circle")))
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
				;
				(gimp-layer-set-offsets (car (gimp-image-get-layer-by-name img "abstract circle")) (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)))
		)

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object shadow")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "abstract circle")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 6.5 6.5 1)
			(gimp-layer-set-name varDupLayer "abstract circle glow")
		)

		;; 
		;; *********************************************************************************************************
			(python-layer-fx-outer-glow (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "abstract circle")) inScFiColor 20 0 16 SCREEN-MODE 2 30 TRUE TRUE)
		;; 

		;; 
		;; ************************************************************************************************************************************
			;;
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "area-brush copy 4")))
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "layer 2")))
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "layer 2 copy")))
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "layer 2 copy 2")))
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "layer 2 copy 3")))
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "sci-fi-path")))
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "sci-fi-path 2")))
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "sci-fi-path 3")))
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "layer 1 copy 2")))
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "layer 1")))
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "marker (tmp)")))
			;; 

			;; 
			(gimp-image-lower-item-to-bottom img (car (gimp-image-get-layer-by-name img "area-brush")))
			(gimp-image-lower-item-to-bottom img (car (gimp-image-get-layer-by-name img "sci-fi-brush")))
			(gimp-item-set-name (car (gimp-image-get-layer-by-name img "background")) "background (original)")
			;;


			;; 
			(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "background-color")) (car (gimp-image-get-layer-by-name img "gradient-fill-with-gradient")) 1)
			(gimp-item-set-name (car (gimp-image-get-layer-by-name img "gradient-fill-with-gradient")) "Background")
			(gimp-item-set-name (car (gimp-image-get-layer-by-name img "gradient-fill-gradient")) "background-light (gradient-fill radial)")

			(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "object light")) (car (gimp-image-get-layer-by-name img "Background")) 0)
			;; 


			;; 
			(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object shadow")))
			(gimp-item-set-name brush-layer-group "Sci-Fi brushes (outside)")
			(gimp-layer-set-mode brush-layer-group SCREEN-MODE)
			(gimp-layer-set-opacity brush-layer-group 100)
			(gimp-image-insert-layer img brush-layer-group 0 -1)

			(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "abstract circle")) (car (gimp-image-get-layer-by-name img "Sci-Fi brushes (outside)")) 0)
			(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "abstract web (outside)")) (car (gimp-image-get-layer-by-name img "Sci-Fi brushes (outside)")) 1)
			(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "abstract web glow (outside)")) (car (gimp-image-get-layer-by-name img "Sci-Fi brushes (outside)")) 1)
			(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "hexagons web (border)")) (car (gimp-image-get-layer-by-name img "Sci-Fi brushes (outside)")) 1)
			(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "hexagons web (border) glow")) (car (gimp-image-get-layer-by-name img "Sci-Fi brushes (outside)")) 1)
			(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "abstract circle glow")) (car (gimp-image-get-layer-by-name img "Sci-Fi brushes (outside)")) 1)
			;; 

			(gimp-image-raise-item img (car (gimp-image-get-layer-by-name img "object shadow")))


			;; 
			(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "layer 1 copy 4")) CLIP-TO-BOTTOM-LAYER)
			(gimp-item-set-name (car (gimp-image-get-layer-by-name img "layer 1 copy 2(b)")) "hexagon particles #4 (glow)")
			(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "hexagon particles #4 (glow)")) DODGE-MODE)

			(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "layer 1 copy 6")) CLIP-TO-BOTTOM-LAYER)
			(gimp-item-set-name (car (gimp-image-get-layer-by-name img "layer 1 copy 4(b)")) "hexagon particles #4 (glow, top)")
			(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "hexagon particles #4 (glow, top)")) SCREEN-MODE)

			(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "layer 1 copy 6(b)")) CLIP-TO-BOTTOM-LAYER)
			(gimp-item-set-name (car (gimp-image-get-layer-by-name img "layer 1 copy 7 (13)")) "hexagon particles #4 (big glow, top)")
			(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "hexagon particles #4 (big glow, top)")) SCREEN-MODE)


			(gimp-item-set-name (car (gimp-image-get-layer-by-name img "layer 4")) "hexagon particles #6")
			(gimp-item-set-name (car (gimp-image-get-layer-by-name img "layer 7")) "hexagon particles #7")
			(gimp-item-set-name (car (gimp-image-get-layer-by-name img "layer 3")) "hexagon particles #8 (main)")
			(gimp-item-set-name (car (gimp-image-get-layer-by-name img "layer 12")) "hexagon particles #2")
			(gimp-item-set-name (car (gimp-image-get-layer-by-name img "layer 11")) "hexagon particles #1")


		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "abstract web (inside)")))
		(gimp-context-set-feather 0)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "hexagon particles #8 (main)")))
		(script-fu-drop-shadow img (car (gimp-image-get-layer-by-name img "abstract web (inside)")) 1 1 4 '(0 0 0) 70 FALSE)
		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "Drop Shadow")) MULTIPLY-MODE)
		(gimp-item-set-name (car (gimp-image-get-layer-by-name img "Drop Shadow")) "hexagon particles #8 (main, shadow)")
		(gimp-selection-none img)


		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "hexagon particles #4 (big glow, top)")))

		;; 
		(gimp-palette-set-background old-bg)
		(gimp-palette-set-foreground old-fg)
		(gimp-context-pop)
		(if (= inUndoMode TRUE) (begin (gimp-image-undo-group-end img)) )

		(gimp-displays-flush)
	) ;;
)