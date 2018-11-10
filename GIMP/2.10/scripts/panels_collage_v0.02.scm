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
;;	v0.02 Panels Collage; Gimp v2.10																	;;
;;	(de) http://www.3d-hobby-art.de/news/214-gimp-skript-fu-vertikale-paneele-foto-collage.html			;;
;;	(eng) http://www.3d-hobby-art.de/en/blog/215-gimp-script-fu-vertical-photo-panels-effect.html		;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(script-fu-register
	"script-fu-panels-collage"													;func name
	"Panels Collage Effect (free) ..."														;menu label
	"transform your photo or image into a nice looking Vertical Panel Portrait"	;desc
	"Stephan W."
	"(c) 2017, 3d-hobby-art.de"													;copyright notice
	"Dec 27, 2017"																;date created
	"RGBA , RGB"																;image type that the script works on
	SF-IMAGE		"Image"						0
	SF-DRAWABLE		"The layer"					0
	SF-ADJUSTMENT	_"Border"					'(5 2 20 1 5 0 0)
	SF-TOGGLE		"Undo Mode?"				FALSE
)
(script-fu-menu-register "script-fu-panels-collage" "<Image>/Script-Fu/Panel Collage")

(define (script-fu-panels-collage img drawable inPanelBorder inUndoMode)

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
	
	(let* ( 
			(bg-layer (car (gimp-image-get-layer-by-name img "background")))
			(brush-mask-layer (car (gimp-image-get-layer-by-name img "brush-mask")))
			(ImageWidth  (car (gimp-image-width  img)))
			(ImageHeight (car (gimp-image-height img)))
			(old-bg (car (gimp-context-get-background)))
			(old-fg (car (gimp-context-get-foreground)))
			
			(bg-overlay-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "bg-overlay" 80 DARKEN-ONLY-MODE)))
			(layer-mask)
		)

		;;	Warning
		;; ************************************************************************************************************************************
		(if  ( = (car (gimp-image-get-layer-by-name img "background")) -1)
			(gimp-message-and-quit "There is no \"background\" layer! Tutorial - please read. \n Keine \"background\" -Ebene gefunden! Bitte lesen Sie mein Tutorial.")
		)
		(if  ( = (car (gimp-image-get-layer-by-name img "brush-mask")) -1)
			(gimp-message-and-quit "There is no \"brush-mask\" layer! Tutorial - please read. \n Keine \"brush-mask\" -Ebene gefunden! Bitte lesen Sie mein Tutorial.")
		)
		(if  ( = (car (gimp-procedural-db-proc-exists "python-layerfx-drop-shadow")) FALSE)
			(gimp-message-and-quit "\"LayerFX\" (Python-Fu) for Gimp 2.8 not installed!! Tutorial - please read. \n \"LayerFX\" (Python-Fu) für Gimp 2.8 nicht installiert. Bitte lesen Sie mein Tutorial.")
		)


		;;	Start....
		;; Undo Mode?
		(if (= inUndoMode TRUE) (begin (gimp-image-undo-group-start img) ) )
		(if (= inUndoMode FALSE) (begin (gimp-image-undo-disable img)) )

		(gimp-context-set-foreground '(0 0 0))
		(gimp-context-set-background '(255 255 255))

		;; add alpha channel if no exists
		(if (= (car (gimp-drawable-has-alpha bg-layer)) FALSE) (begin (gimp-layer-add-alpha bg-layer)) (begin ))		


		;;	bg-overlay-layer
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img bg-layer)
		(gimp-image-insert-layer img bg-overlay-layer 0 -1)
		(gimp-image-set-active-layer img bg-overlay-layer)
		(gimp-context-set-foreground '(0 0 0))
		(gimp-edit-fill bg-overlay-layer FOREGROUND-FILL)
		(gimp-selection-none img)
		
		
		;;	fill black! brush-mask-layer
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img brush-mask-layer)
		(gimp-context-set-foreground '(0 0 0))
		(gimp-selection-layer-alpha brush-mask-layer)
		(gimp-edit-fill brush-mask-layer FOREGROUND-FILL)	
		
		
		;;	Panel 01
		;; ************************************************************************************************************************************
		(plug-in-autocrop-layer RUN-NONINTERACTIVE img brush-mask-layer)
		(gimp-image-set-active-layer img brush-mask-layer)
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-scale varDupLayer (+ (* (/ (car (gimp-drawable-width varDupLayer)) 100) 16.66666) inPanelBorder) (+ (car (gimp-drawable-height varDupLayer)) inPanelBorder) TRUE)
			(gimp-layer-translate varDupLayer (- (* (/ (car (gimp-drawable-width varDupLayer)) 100) 50)) 0 )
			(gimp-layer-set-name varDupLayer "Panel 01")
		)
		(gimp-item-set-visible brush-mask-layer FALSE)
		
		
		;;	Panel 02
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Panel 01")) )
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-translate varDupLayer (* (/ (car (gimp-drawable-width varDupLayer)) 100) 92.22222) 0 )
			(gimp-layer-set-name varDupLayer "Panel 02")
		)

		
		;;	Panel 03
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Panel 02")) )
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-translate varDupLayer (* (/ (car (gimp-drawable-width varDupLayer)) 100) 94.44444) 0 )
			(gimp-layer-set-name varDupLayer "Panel 03")
		)

		
		;;	Panel 04
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Panel 03")) )
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-translate varDupLayer (* (/ (car (gimp-drawable-width varDupLayer)) 100) 93.22222) 0 )
			(gimp-layer-set-name varDupLayer "Panel 04")
		)

		
		;;	Panel 05
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Panel 01")) )
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-translate varDupLayer (- (* (/ (car (gimp-drawable-width varDupLayer)) 100) 96.66666)) 0 )
			(gimp-layer-set-name varDupLayer "Panel 05")
		)

		
		;;	Panel 06
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Panel 05")) )
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-translate varDupLayer (- (* (/ (car (gimp-drawable-width varDupLayer)) 100) 97.22222)) 0 )
			(gimp-layer-set-name varDupLayer "Panel 06")
		)
		

		;;	Random scale Panels 01 - 06
		;; ************************************************************************************************************************************
		(gimp-layer-scale (car (gimp-image-get-layer-by-name img "Panel 01")) (+ (* (car (gimp-drawable-width (car (gimp-image-get-layer-by-name img "Panel 01")))) (/ (rand 3) 100)) (car (gimp-drawable-width (car (gimp-image-get-layer-by-name img "Panel 01"))))) (+ (* (car (gimp-drawable-height (car (gimp-image-get-layer-by-name img "Panel 01")))) (/ (rand 5) 100)) (car (gimp-drawable-height (car (gimp-image-get-layer-by-name img "Panel 01"))))) TRUE)
		(gimp-layer-scale (car (gimp-image-get-layer-by-name img "Panel 06")) (+ (* (car (gimp-drawable-width (car (gimp-image-get-layer-by-name img "Panel 06")))) (/ (rand 12) 100)) (car (gimp-drawable-width (car (gimp-image-get-layer-by-name img "Panel 06"))))) (+ (* (car (gimp-drawable-height (car (gimp-image-get-layer-by-name img "Panel 06")))) (/ (rand 9) 100)) (car (gimp-drawable-height (car (gimp-image-get-layer-by-name img "Panel 06"))))) TRUE)
		(gimp-layer-scale (car (gimp-image-get-layer-by-name img "Panel 02")) (+ (* (car (gimp-drawable-width (car (gimp-image-get-layer-by-name img "Panel 02")))) (/ (rand 8) 100)) (car (gimp-drawable-width (car (gimp-image-get-layer-by-name img "Panel 02"))))) (+ (* (car (gimp-drawable-height (car (gimp-image-get-layer-by-name img "Panel 02")))) (/ (rand 6) 100)) (car (gimp-drawable-height (car (gimp-image-get-layer-by-name img "Panel 02"))))) TRUE)
		(gimp-layer-scale (car (gimp-image-get-layer-by-name img "Panel 03")) (+ (* (car (gimp-drawable-width (car (gimp-image-get-layer-by-name img "Panel 03")))) (/ (rand 10) 100)) (car (gimp-drawable-width (car (gimp-image-get-layer-by-name img "Panel 03"))))) (+ (* (car (gimp-drawable-height (car (gimp-image-get-layer-by-name img "Panel 03")))) (/ (rand 18) 100)) (car (gimp-drawable-height (car (gimp-image-get-layer-by-name img "Panel 03"))))) TRUE)
		(gimp-layer-scale (car (gimp-image-get-layer-by-name img "Panel 04")) (+ (* (car (gimp-drawable-width (car (gimp-image-get-layer-by-name img "Panel 04")))) (/ (rand 20) 100)) (car (gimp-drawable-width (car (gimp-image-get-layer-by-name img "Panel 04"))))) (+ (* (car (gimp-drawable-height (car (gimp-image-get-layer-by-name img "Panel 04")))) (/ (rand 9) 100)) (car (gimp-drawable-height (car (gimp-image-get-layer-by-name img "Panel 04"))))) TRUE)
		(gimp-layer-scale (car (gimp-image-get-layer-by-name img "Panel 05")) (+ (* (car (gimp-drawable-width (car (gimp-image-get-layer-by-name img "Panel 05")))) (/ (rand 6) 100)) (car (gimp-drawable-width (car (gimp-image-get-layer-by-name img "Panel 05"))))) (+ (* (car (gimp-drawable-height (car (gimp-image-get-layer-by-name img "Panel 05")))) (/ (rand 12) 100)) (car (gimp-drawable-height (car (gimp-image-get-layer-by-name img "Panel 05"))))) TRUE)


		;;	Panel 01 Border
		;; ************************************************************************************************************************************
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "Panel 01")))
		(gimp-selection-shrink img inPanelBorder)
		(gimp-selection-invert img)
		(gimp-context-set-foreground '(255 255 255))
		(gimp-edit-fill (car (gimp-image-get-layer-by-name img "Panel 01")) FOREGROUND-FILL)
		
		;;	Panel 02 Border
		;; ************************************************************************************************************************************
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "Panel 02")))
		(gimp-selection-shrink img inPanelBorder)
		(gimp-selection-invert img)
		(gimp-context-set-foreground '(255 255 255))
		(gimp-edit-fill (car (gimp-image-get-layer-by-name img "Panel 02")) FOREGROUND-FILL)		
		
		;;	Panel 03 Border
		;; ************************************************************************************************************************************
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "Panel 03")))
		(gimp-selection-shrink img inPanelBorder)
		(gimp-selection-invert img)
		(gimp-context-set-foreground '(255 255 255))
		(gimp-edit-fill (car (gimp-image-get-layer-by-name img "Panel 03")) FOREGROUND-FILL)

		;;	Panel 04 Border
		;; ************************************************************************************************************************************
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "Panel 04")))
		(gimp-selection-shrink img inPanelBorder)
		(gimp-selection-invert img)
		(gimp-context-set-foreground '(255 255 255))
		(gimp-edit-fill (car (gimp-image-get-layer-by-name img "Panel 04")) FOREGROUND-FILL)

		;;	Panel 05 Border
		;; ************************************************************************************************************************************
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "Panel 05")))
		(gimp-selection-shrink img inPanelBorder)
		(gimp-selection-invert img)
		(gimp-context-set-foreground '(255 255 255))
		(gimp-edit-fill (car (gimp-image-get-layer-by-name img "Panel 05")) FOREGROUND-FILL)

		;;	Panel 06 Border
		;; ************************************************************************************************************************************
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "Panel 06")))
		(gimp-selection-shrink img inPanelBorder)
		(gimp-selection-invert img)
		(gimp-context-set-foreground '(255 255 255))
		(gimp-edit-fill (car (gimp-image-get-layer-by-name img "Panel 06")) FOREGROUND-FILL)

		(gimp-selection-none img)
		
		;;	random Panel rotate
		;; ************************************************************************************************************************************
		(gimp-item-transform-rotate (car (gimp-image-get-layer-by-name img "Panel 01")) (/ (rand 6) 100) TRUE 0 0)
		(gimp-item-transform-rotate (car (gimp-image-get-layer-by-name img "Panel 02")) (-(/ (rand 8) 100)) TRUE 0 0)
		(gimp-item-transform-rotate (car (gimp-image-get-layer-by-name img "Panel 06")) (-(/ (rand 10) 100)) TRUE 0 0)
		(gimp-item-transform-rotate (car (gimp-image-get-layer-by-name img "Panel 05")) (/ (rand 7) 100) TRUE 0 0)
		(gimp-item-transform-rotate (car (gimp-image-get-layer-by-name img "Panel 03")) (/ (rand 5) 100) TRUE 0 0)
		(gimp-item-transform-rotate (car (gimp-image-get-layer-by-name img "Panel 04")) (-(/ (rand 6) 100)) TRUE 0 0)

		(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "Panel 01")))
		(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "Panel 02")))
		(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "Panel 03")))
		(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "Panel 04")))
		(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "Panel 05")))
		(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "Panel 06")))
		
		(gimp-image-remove-layer img brush-mask-layer)
		
		
		;;	copy background and place it into "Panel 01" + "Panel 01" Shadow + "Panel 01" Border
		;; ************************************************************************************************************************************
		(plug-in-antialias RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "Panel 01")))
		(gimp-by-color-select-full (car (gimp-image-get-layer-by-name img "Panel 01")) '(0 0 0) 150 CHANNEL-OP-ADD TRUE TRUE 2 2 FALSE FALSE 0)
		(gimp-selection-feather img 2)
		(gimp-selection-grow img 2)
		(gimp-item-set-name ( car(gimp-selection-save img)) "Panel 01 bg-selection")
		(gimp-selection-none img)
		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Panel 01")))
		(let* (
				(varDupLayer (car (gimp-layer-copy bg-layer 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 6)
			(gimp-selection-load (car (gimp-image-get-channel-by-name img "Panel 01 bg-selection")))
			(set! layer-mask (car (gimp-layer-create-mask varDupLayer ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img varDupLayer layer-mask)
			(gimp-selection-none img)
			(gimp-layer-set-name varDupLayer "bg -Panel 01")
		)
		
		;;	"Panel 01" Shadow
		(python-layerfx-drop-shadow RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "Panel 01")) '(0 0 0) (+ (rand 20) 70) 0 0 MULTIPLY-MODE (+ (rand 4) 5) (+ (rand 15) 15) 120 8 FALSE TRUE)
		(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "Panel 01")))
		
		;;	"Panel 01" Border
		(gimp-selection-load (car (gimp-image-get-channel-by-name img "Panel 01 bg-selection")))
		(gimp-selection-shrink img 1)
		(gimp-selection-invert img)
		(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "Panel 01")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "Panel 01")) layer-mask)		
		(gimp-selection-none img)
		
		(plug-in-gauss RUN-NONINTERACTIVE img (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "Panel 01")))) 2 2 1)
		
		
		;;	copy background and place it into "Panel 02" + "Panel 02" Shadow + "Panel 02" Border
		;; ************************************************************************************************************************************
		(plug-in-antialias RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "Panel 02")))
		(gimp-by-color-select-full (car (gimp-image-get-layer-by-name img "Panel 02")) '(0 0 0) 150 CHANNEL-OP-ADD TRUE TRUE 2 2 FALSE FALSE 0)
		(gimp-selection-feather img 2)
		(gimp-selection-grow img 2)
		(gimp-item-set-name ( car(gimp-selection-save img)) "Panel 02 bg-selection")
		(gimp-selection-none img)
		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Panel 02")))
		(let* (
				(varDupLayer (car (gimp-layer-copy bg-layer 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 3)
			(gimp-selection-load (car (gimp-image-get-channel-by-name img "Panel 02 bg-selection")))
			(set! layer-mask (car (gimp-layer-create-mask varDupLayer ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img varDupLayer layer-mask)
			(gimp-selection-none img)
			(gimp-layer-set-name varDupLayer "bg -Panel 02")
		)
		
		;;	"Panel 02" Shadow
		(python-layerfx-drop-shadow RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "Panel 02")) '(0 0 0) (+ (rand 25) 70) 0 0 MULTIPLY-MODE (+ (rand 4) 5) (+ (rand 15) 15) 120 8 FALSE TRUE)
		(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "Panel 02")))
		
		;;	"Panel 02" Border
		(gimp-selection-load (car (gimp-image-get-channel-by-name img "Panel 02 bg-selection")))
		(gimp-selection-shrink img 1)
		(gimp-selection-invert img)
		(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "Panel 02")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "Panel 02")) layer-mask)		
		(gimp-selection-none img)
		
		(plug-in-gauss RUN-NONINTERACTIVE img (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "Panel 02")))) 2 2 1)		
		
		
		;;	copy background and place it into "Panel 03" + "Panel 03" Shadow + "Panel 03" Border
		;; ************************************************************************************************************************************
		(plug-in-antialias RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "Panel 03")))
		(gimp-by-color-select-full (car (gimp-image-get-layer-by-name img "Panel 03")) '(0 0 0) 150 CHANNEL-OP-ADD TRUE TRUE 2 2 FALSE FALSE 0)
		(gimp-selection-feather img 2)
		(gimp-selection-grow img 2)
		(gimp-item-set-name ( car(gimp-selection-save img)) "Panel 03 bg-selection")
		(gimp-selection-none img)
		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Panel 03")))
		(let* (
				(varDupLayer (car (gimp-layer-copy bg-layer 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 2)
			(gimp-selection-load (car (gimp-image-get-channel-by-name img "Panel 03 bg-selection")))
			(set! layer-mask (car (gimp-layer-create-mask varDupLayer ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img varDupLayer layer-mask)
			(gimp-selection-none img)
			(gimp-layer-set-name varDupLayer "bg -Panel 03")
		)
		
		;;	"Panel 03" Shadow
		(python-layerfx-drop-shadow RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "Panel 03")) '(0 0 0) (+ (rand 25) 65) 0 0 MULTIPLY-MODE (+ (rand 4) 5) (+ (rand 10) 15) 120 8 FALSE TRUE)
		(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "Panel 03")))
		
		;;	"Panel 03" Border
		(gimp-selection-load (car (gimp-image-get-channel-by-name img "Panel 03 bg-selection")))
		(gimp-selection-shrink img 1)
		(gimp-selection-invert img)
		(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "Panel 03")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "Panel 03")) layer-mask)		
		(gimp-selection-none img)
		
		(plug-in-gauss RUN-NONINTERACTIVE img (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "Panel 03")))) 2 2 1)
		
		
		;;	copy background and place it into "Panel 04" + "Panel 04" Shadow + "Panel 04" Border
		;; ************************************************************************************************************************************
		(plug-in-antialias RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "Panel 04")))
		(gimp-by-color-select-full (car (gimp-image-get-layer-by-name img "Panel 04")) '(0 0 0) 150 CHANNEL-OP-ADD TRUE TRUE 2 2 FALSE FALSE 0)
		(gimp-selection-feather img 2)
		(gimp-selection-grow img 2)
		(gimp-item-set-name ( car(gimp-selection-save img)) "Panel 04 bg-selection")
		(gimp-selection-none img)
		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Panel 04")))
		(let* (
				(varDupLayer (car (gimp-layer-copy bg-layer 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 1)
			(gimp-selection-load (car (gimp-image-get-channel-by-name img "Panel 04 bg-selection")))
			(set! layer-mask (car (gimp-layer-create-mask varDupLayer ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img varDupLayer layer-mask)
			(gimp-selection-none img)
			(gimp-layer-set-name varDupLayer "bg -Panel 04")
		)
		
		;;	"Panel 04" Shadow
		(python-layerfx-drop-shadow RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "Panel 04")) '(0 0 0) (+ (rand 25) 65) 0 0 MULTIPLY-MODE (+ (rand 4) 3) (+ (rand 10) 15) 120 8 FALSE TRUE)
		(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "Panel 04")))
		
		;;	"Panel 04" Border
		(gimp-selection-load (car (gimp-image-get-channel-by-name img "Panel 04 bg-selection")))
		(gimp-selection-shrink img 1)
		(gimp-selection-invert img)
		(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "Panel 04")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "Panel 04")) layer-mask)		
		(gimp-selection-none img)
		
		(plug-in-gauss RUN-NONINTERACTIVE img (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "Panel 04")))) 2 2 1)		
		
		
		;;	copy background and place it into "Panel 05" + "Panel 05" Shadow + "Panel 05" Border
		;; ************************************************************************************************************************************
		(plug-in-antialias RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "Panel 05")))
		(gimp-by-color-select-full (car (gimp-image-get-layer-by-name img "Panel 05")) '(0 0 0) 150 CHANNEL-OP-ADD TRUE TRUE 2 2 FALSE FALSE 0)
		(gimp-selection-feather img 2)
		(gimp-selection-grow img 2)
		(gimp-item-set-name ( car(gimp-selection-save img)) "Panel 05 bg-selection")
		(gimp-selection-none img)
		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Panel 05")))
		(let* (
				(varDupLayer (car (gimp-layer-copy bg-layer 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 8)
			(gimp-selection-load (car (gimp-image-get-channel-by-name img "Panel 05 bg-selection")))
			(set! layer-mask (car (gimp-layer-create-mask varDupLayer ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img varDupLayer layer-mask)
			(gimp-selection-none img)
			(gimp-layer-set-name varDupLayer "bg -Panel 05")
		)
		
		;;	"Panel 05" Shadow
		(python-layerfx-drop-shadow RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "Panel 05")) '(0 0 0) (+ (rand 25) 65) 0 0 MULTIPLY-MODE (+ (rand 4) 3) (+ (rand 10) 15) 120 8 FALSE TRUE)
		(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "Panel 05")))
		
		;;	"Panel 05" Border
		(gimp-selection-load (car (gimp-image-get-channel-by-name img "Panel 05 bg-selection")))
		(gimp-selection-shrink img 1)
		(gimp-selection-invert img)
		(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "Panel 05")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "Panel 05")) layer-mask)		
		(gimp-selection-none img)
		
		(plug-in-gauss RUN-NONINTERACTIVE img (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "Panel 05")))) 2 2 1)		
		
		
		;;	copy background and place it into "Panel 06" + "Panel 06" Shadow + "Panel 06" Border
		;; ************************************************************************************************************************************
		(plug-in-antialias RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "Panel 06")))
		(gimp-by-color-select-full (car (gimp-image-get-layer-by-name img "Panel 06")) '(0 0 0) 150 CHANNEL-OP-ADD TRUE TRUE 2 2 FALSE FALSE 0)
		(gimp-selection-feather img 2)
		(gimp-selection-grow img 2)
		(gimp-item-set-name ( car(gimp-selection-save img)) "Panel 06 bg-selection")
		(gimp-selection-none img)
		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Panel 06")))
		(let* (
				(varDupLayer (car (gimp-layer-copy bg-layer 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 7)
			(gimp-selection-load (car (gimp-image-get-channel-by-name img "Panel 06 bg-selection")))
			(set! layer-mask (car (gimp-layer-create-mask varDupLayer ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img varDupLayer layer-mask)
			(gimp-selection-none img)
			(gimp-layer-set-name varDupLayer "bg -Panel 06")
		)
		
		;;	"Panel 06" Shadow
		(python-layerfx-drop-shadow RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "Panel 06")) '(0 0 0) (+ (rand 25) 75) 0 0 MULTIPLY-MODE (+ (rand 4) 3) (+ (rand 10) 15) 120 8 FALSE TRUE)
		(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "Panel 06")))
		
		;;	"Panel 06" Border
		(gimp-selection-load (car (gimp-image-get-channel-by-name img "Panel 06 bg-selection")))
		(gimp-selection-shrink img 1)
		(gimp-selection-invert img)
		(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "Panel 06")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "Panel 06")) layer-mask)		
		(gimp-selection-none img)
		
		(plug-in-gauss RUN-NONINTERACTIVE img (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "Panel 06")))) 2 2 1)		

		
		;;	Finish
		(gimp-palette-set-background old-bg)
		(gimp-palette-set-foreground old-fg)
		(if (= inUndoMode TRUE) (begin (gimp-image-undo-group-end img)) )
		(if (= inUndoMode FALSE) (begin (gimp-image-undo-enable img)) )

		(gimp-displays-flush)
		;;	END....
	)
)