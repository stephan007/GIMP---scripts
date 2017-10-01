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
;;	v0.01 Explode; Gimp v2.8.18																			;;
;;	(de) http://www.3d-hobby-art.de/news/208-gimp-skript-fu-explode.html								;;
;;	(eng) http://www.3d-hobby-art.de/en/blog/209-gimp-script-fu-explode.html							;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(script-fu-register
	"script-fu-explode"													;func name
	"Explode ..."														;menu label
	"Add special stone explosion effects to your photo."				;desc
	"Stephan W."
	"(c) 2017, 3d-hobby-art.de"											;copyright notice
	"September 01, 2017"												;date created
	"RGBA , RGB"														;image type that the script works on
	SF-IMAGE		"Image"						0
	SF-DRAWABLE		"The layer"					0
	SF-COLOR		_"Glow"						'(0 232 241)
	SF-TOGGLE		"Run Interactive Mode?"		FALSE
	SF-TOGGLE		"Undo Mode?"				FALSE
)
(script-fu-menu-register "script-fu-explode" "<Image>/Script-Fu/Explode")

(define (script-fu-explode img drawable inGlowColor inRunMode inUndoMode)

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
			
			(fill-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "background-color" 100 NORMAL)))
			
			(clouds-diff-layer (car (gimp-layer-new img ImageWidth ImageHeight (car (gimp-drawable-type-with-alpha drawable)) "clouds diff" 100 DIFFERENCE-MODE)))
			
			
			(cracks-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "object outer cracks" 100 NORMAL)))
			(fill-glow-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "object inner cracks -glow" 100 NORMAL)))
			(cracks-layer-mask)
			
			(copy-visible-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "copy-visible" 100 NORMAL)))
			(copy-visible-layer2 (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "Layer 9" 100 NORMAL)))
			(layer-mask)
			(stones-group (car (gimp-layer-group-new img)))
			
			(dots-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "Dots" 100 NORMAL)))
			(dots-layer-group (car (gimp-layer-group-new img)))
			
			(cracks-layer-group (car (gimp-layer-group-new img)))
			(object-brush-layer-group (car (gimp-layer-group-new img)))
			
			(clouds-layer-mask)
			(floating-selection)
			(seed)
			
			(object-layer-high-pass)
			(object-layer-high-pass-dupl)
			
			(texture-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "bg_t_1" 100 NORMAL)))
			(texture1-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "bg_t_5" 100 HARDLIGHT-MODE)))
			(texture-group (car (gimp-layer-group-new img)))
		)

		;;	Warning
		;; ************************************************************************************************************************************
		(if  ( = (car (gimp-image-get-layer-by-name img "background")) -1)
			(gimp-message-and-quit "There is no \"background\" layer! Tutorial - please read. \n Keine \"background\" -Ebene gefunden! Bitte lesen Sie mein Tutorial.")
		)
		(if  ( = (car (gimp-image-get-layer-by-name img "brush-mask")) -1)
			(gimp-message-and-quit "There is no \"brush-mask\" layer! Tutorial - please read. \n Keine \"brush-mask\" -Ebene gefunden! Bitte lesen Sie mein Tutorial.")
		)
		(if  ( = (car (gimp-procedural-db-proc-exists "python-layer-fx-outer-glow")) FALSE)
			(gimp-message-and-quit "\"LayerFX\" (Python-Fu) for Gimp 2.8 not installed!! Tutorial - please read. \n  \"LayerFX\" (Python-Fu) für Gimp 2.8 nicht installiert. Bitte lesen Sie mein Tutorial.")
		)
		
		;;	Start....
		;;
		(if (= inUndoMode TRUE) (begin (gimp-image-undo-group-start img)) )

		(gimp-context-set-foreground '(0 0 0))
		(gimp-context-set-background '(255 255 255))

		
		;;	
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img bg-layer)
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "brush-mask")))
			(gimp-selection-invert img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(gimp-layer-set-name varDupLayer "base object")
		)

		
		;;	
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img bg-layer)
		(gimp-image-insert-layer img fill-layer 0 -1)
		(gimp-image-set-active-layer img fill-layer)
		(gimp-context-set-foreground '(0 0 0))
		(gimp-edit-fill fill-layer FOREGROUND-FILL)
		
		
		;;	
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img brush-mask-layer)
		(gimp-layer-resize-to-image-size brush-mask-layer)
		(let* (
				(varDupLayer (car (gimp-layer-copy brush-mask-layer 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-resize-to-image-size varDupLayer)
			(gimp-layer-scale-full varDupLayer (* ImageWidth 1.14) (* ImageHeight 1.14) TRUE INTERPOLATION-CUBIC)
			(gimp-layer-resize-to-image-size varDupLayer)
			(gimp-layer-set-name varDupLayer "brush-mask-scale")
			(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "brush-mask-scale")) FALSE)
		)
		(gimp-image-set-active-layer img brush-mask-layer)
		(let* (
				(varDupLayer (car (gimp-layer-copy brush-mask-layer 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-resize-to-image-size varDupLayer)
			(gimp-layer-scale-full varDupLayer (* ImageWidth 0.92) (* ImageHeight 0.92) TRUE INTERPOLATION-CUBIC)
			(gimp-layer-resize-to-image-size varDupLayer)
			(gimp-layer-set-name varDupLayer "brush-mask-scale 2")
			(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "brush-mask-scale 2")) FALSE)
		)
		(gimp-item-set-visible brush-mask-layer FALSE)
		
		
		;;	
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "base object")))
		(gimp-image-insert-layer img texture-layer 0 -1)
		(gimp-image-set-active-layer img texture-layer)
		(gimp-context-set-foreground '(0 0 0))
		(gimp-edit-fill texture-layer FOREGROUND-FILL)	
		
		(set! seed (if (number? seed) seed (realtime)))
		(plug-in-solid-noise RUN-NONINTERACTIVE img texture-layer TRUE FALSE seed 10 12 12)
		(plug-in-gimpressionist RUN-NONINTERACTIVE img texture-layer "explode")
		(plug-in-gimpressionist RUN-NONINTERACTIVE img texture-layer "explode2")
		(plug-in-sharpen RUN-NONINTERACTIVE img texture-layer 30)

		(gimp-image-set-active-layer img texture-layer)
		(let* (
				(varDupLayer (car (gimp-layer-copy texture-layer 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-whirl-pinch RUN-NONINTERACTIVE img varDupLayer 50 0 1)
			(gimp-layer-set-mode varDupLayer DARKEN-ONLY-MODE)
			(gimp-image-merge-down img varDupLayer EXPAND-AS-NECESSARY)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "brush-mask-scale")))
			(gimp-selection-feather img (+ 290 (rand 40)))
			(set! clouds-layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "bg_t_1")) ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "bg_t_1")) clouds-layer-mask)
			(gimp-selection-none img)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "brush-mask")))
			(gimp-selection-shrink img 30)
			(gimp-selection-feather img (+ 75 (rand 20)))
			(gimp-context-set-foreground '(0 0 0))
			(gimp-edit-fill clouds-layer-mask FOREGROUND-FILL)
			(gimp-selection-none img)
		)
		
		;;	
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "bg_t_1")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "bg_t_1")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-image-remove-layer-mask img varDupLayer MASK-APPLY)
			(gimp-layer-set-mode varDupLayer SCREEN-MODE)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "base object")))
			(gimp-selection-invert img)
			(set! layer-mask (car (gimp-layer-create-mask varDupLayer ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img varDupLayer layer-mask)
			(gimp-selection-none img)
			(gimp-layer-set-opacity varDupLayer 40)
			(gimp-layer-set-name varDupLayer "bg_t_2")
		)
		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "bg_t_2")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "bg_t_1")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-edge RUN-NONINTERACTIVE img varDupLayer 3 1 3)
			(gimp-layer-set-mode varDupLayer HARDLIGHT-MODE)
			(gimp-layer-set-opacity varDupLayer 100)
			(gimp-layer-set-name varDupLayer "bg_t_3")
		)
		
		(gimp-item-set-visible bg-layer FALSE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "base object")) FALSE)
		(gimp-item-set-visible fill-layer FALSE)
		
		;;	
		;; ************************************************************************************************************************************
		(plug-in-gauss RUN-NONINTERACTIVE img (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "bg_t_1")))) 350 350 1)
		(plug-in-gauss RUN-NONINTERACTIVE img (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "bg_t_1")))) 190 190 1)

		;;	
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "bg_t_3")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "bg_t_1")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-name varDupLayer "bg_t_4")
		)		

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "bg_t_4")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "bg_t_3")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-remove-mask varDupLayer MASK-DISCARD)
			(gimp-image-merge-down img varDupLayer EXPAND-AS-NECESSARY)
		)

		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "bg_t_4")) SOFTLIGHT-MODE)
		(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "bg_t_4")) 70)
		
		;;	
		;; ************************************************************************************************************************************
		(gimp-edit-copy-visible img)
		(gimp-image-add-layer img texture1-layer 3)
		(set! floating-selection (car (gimp-edit-paste texture1-layer 0)))
		(gimp-floating-sel-anchor floating-selection)

		;;	
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "bg_t_5")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "bg_t_1")) 1)))
				(varDupLayer2 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "bg_t_3")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-name varDupLayer "bg_t_6")
			(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "bg_t_6")))
			(gimp-image-insert-layer img varDupLayer2 0 -1)
			(gimp-image-merge-down img varDupLayer2 EXPAND-AS-NECESSARY)
		)		

		(gimp-layer-scale-full (car (gimp-image-get-layer-by-name img "bg_t_6")) ImageWidth (* ImageHeight 1.4) TRUE INTERPOLATION-CUBIC)
		(gimp-layer-translate (car (gimp-image-get-layer-by-name img "bg_t_6")) 0 (-(/ (-(* ImageHeight 1.3) ImageHeight) 2)))
		(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "bg_t_6")))
		(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "bg_t_6")) 28)

		;;	
		;; ************************************************************************************************************************************
		(gimp-item-set-name texture-group "Texture Group")
		(gimp-layer-set-mode texture-group NORMAL-MODE)
		(gimp-layer-set-opacity texture-group 100)
		(gimp-image-insert-layer img texture-group 0 3)
		
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "bg_t_1")) (car (gimp-image-get-layer-by-name img "Texture Group")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "bg_t_2")) (car (gimp-image-get-layer-by-name img "Texture Group")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "bg_t_3")) (car (gimp-image-get-layer-by-name img "Texture Group")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "bg_t_4")) (car (gimp-image-get-layer-by-name img "Texture Group")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "bg_t_5")) (car (gimp-image-get-layer-by-name img "Texture Group")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "bg_t_6")) (car (gimp-image-get-layer-by-name img "Texture Group")) 0)
		;; 
		;; ************************************************************************************************************************************


		;;	
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "base object")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "base object")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-desaturate-full varDupLayer DESATURATE-LIGHTNESS)
			(gimp-levels-stretch varDupLayer)
			(gimp-layer-set-name varDupLayer "object edge detail")
		)

		
		
		;;	
		;; ************************************************************************************************************************************
		(gimp-image-add-layer img cracks-layer 3)
		(gimp-context-set-foreground '(0 0 0))
		(gimp-edit-fill cracks-layer FOREGROUND-FILL)
		(gimp-image-set-active-layer img cracks-layer)
		(set! seed (if (number? seed) seed (realtime)))
		(plug-in-solid-noise RUN-INTERACTIVE img cracks-layer TRUE FALSE seed 14 15.5 15.5)
		
		(gimp-image-add-layer img clouds-diff-layer 3)
		(gimp-drawable-fill clouds-diff-layer TRANSPARENT-FILL)		
		
		(plug-in-solid-noise RUN-INTERACTIVE img clouds-diff-layer TRUE FALSE seed 14 15.6 15.6)
		(gimp-image-merge-down img clouds-diff-layer EXPAND-AS-NECESSARY)	
		
		(gimp-levels-stretch (car (gimp-image-get-layer-by-name img "object outer cracks")))
		(gimp-by-color-select-full (car (gimp-image-get-layer-by-name img "object outer cracks")) '(0 0 0) 2 CHANNEL-OP-ADD TRUE TRUE 2 2 TRUE FALSE SELECT-CRITERION-COMPOSITE)

		(set! cracks-layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "object outer cracks")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "object outer cracks")) cracks-layer-mask)
		(gimp-image-remove-layer-mask img (car (gimp-image-get-layer-by-name img "object outer cracks")) MASK-APPLY)
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object outer cracks")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object outer cracks")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-name varDupLayer "object inner cracks -bevel")
		)
		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object outer cracks")))
		
		;;	
		;; ************************************************************************************************************************************
		(python-layer-fx-outer-glow (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "object outer cracks")) '(0 0 0) 22 0 0 OVERLAY-MODE 0 14 TRUE TRUE)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "brush-mask")))
		(gimp-selection-shrink img 20)
		(gimp-selection-invert img)
		(gimp-selection-feather img 12)
		(set! cracks-layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "object outer cracks")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "object outer cracks")) cracks-layer-mask)
		(gimp-image-remove-layer-mask img (car (gimp-image-get-layer-by-name img "object outer cracks")) MASK-APPLY)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "brush-mask-scale")))
		(gimp-selection-feather img (+ 38 (rand 10)))
		(set! cracks-layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "object outer cracks")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "object outer cracks")) cracks-layer-mask)
		;;
		
		
		
		;;	
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object inner cracks -bevel")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -bevel")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-name varDupLayer "object inner cracks -bevel copy")
		)		
		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object inner cracks -bevel copy")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -bevel copy")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-name varDupLayer "object inner cracks -bevel copy 2")
		)		
		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object inner cracks -bevel copy 2")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -bevel copy 2")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-image-merge-down img varDupLayer EXPAND-AS-NECESSARY)
		)
		
		(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "object inner cracks -bevel copy 2")) EXPAND-AS-NECESSARY)
		(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "object inner cracks -bevel copy")) EXPAND-AS-NECESSARY)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "brush-mask")))
		(gimp-selection-shrink img 48)
		(gimp-selection-feather img 10)
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "object inner cracks -bevel")))
		(gimp-selection-none img)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "brush-mask")))
		(gimp-selection-invert img)
		(gimp-selection-feather img 0)
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "object inner cracks -bevel")))
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "brush-mask")))
		(set! cracks-layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "object inner cracks -bevel")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "object inner cracks -bevel")) cracks-layer-mask)
		(gimp-image-remove-layer-mask img (car (gimp-image-get-layer-by-name img "object inner cracks -bevel")) MASK-APPLY)
		(gimp-selection-none img)
		(python-layer-fx-bevel-emboss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "object inner cracks -bevel")) 3 14 0 4 0 122 26 0 '(255 255 255) SCREEN-MODE 60 '(0 0 0) MULTIPLY-MODE 72 0 FALSE "Pine" 100 100 FALSE FALSE)
		

		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "brush-mask-scale 2")))
		(gimp-selection-invert img)
		(set! cracks-layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "object inner cracks -bevel")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "object inner cracks -bevel")) cracks-layer-mask)		
		(gimp-selection-none img)
		

		;; 
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "object inner cracks -bevel")) 0 3)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "object inner cracks -bevel-shadow")) 0 3)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "object inner cracks -bevel-highlight")) 0 3)
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "object inner cracks -bevel-with-bevel")))
		; 
		
		
		
		;	Cracks red Glow
		; ************************************************************************************************************************************
		(gimp-image-insert-layer img fill-glow-layer 0 3)
		(gimp-context-set-foreground inGlowColor)
		(gimp-edit-fill fill-glow-layer FOREGROUND-FILL)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "object inner cracks -bevel")))
		(set! cracks-layer-mask (car (gimp-layer-create-mask fill-glow-layer ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img fill-glow-layer cracks-layer-mask)
		(gimp-selection-none img)
		(gimp-image-remove-layer-mask img fill-glow-layer MASK-APPLY)
		(plug-in-gauss RUN-NONINTERACTIVE img fill-glow-layer 4 4 1)
		(gimp-image-set-active-layer img fill-glow-layer)
		
		(let* (
				(varDupLayer (car (gimp-layer-copy fill-glow-layer 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-gauss RUN-NONINTERACTIVE img varDupLayer (+ 25 (rand 20)) (+ 25 (rand 20)) 1)
			(gimp-layer-set-name varDupLayer "object inner cracks -glow (2)")
		)		
			(let* (
					(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -glow (2)")) 1)))
				)
				(gimp-image-insert-layer img varDupLayer 0 -1)
				(plug-in-gauss RUN-NONINTERACTIVE img varDupLayer (+ 55 (rand 20)) (+ 55 (rand 20)) 1)
				(gimp-image-merge-down img varDupLayer CLIP-TO-BOTTOM-LAYER)
			)		

		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "object inner cracks -glow")) DODGE-MODE)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "brush-mask-scale 2")))
		(gimp-selection-invert img)
		(set! cracks-layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "object inner cracks -glow")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "object inner cracks -glow")) cracks-layer-mask)
		(set! cracks-layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "object inner cracks -glow (2)")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "object inner cracks -glow (2)")) cracks-layer-mask)		
		(gimp-selection-none img)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "object inner cracks -bevel-highlight")))
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "object inner cracks -glow")))
		(gimp-selection-none img)
		
		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object inner cracks -glow (2)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -glow (2)")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-gauss RUN-NONINTERACTIVE img varDupLayer 30 30 1)
			(gimp-image-remove-layer-mask img varDupLayer MASK-DISCARD)
			(gimp-layer-set-mode varDupLayer LIGHTEN-ONLY-MODE)
			(gimp-layer-set-name varDupLayer "object inner cracks -glow (3)")
		)
		; 


		
		
		;	
		; ************************************************************************************************************************************
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "object edge detail")) TRUE)
		(gimp-item-set-visible fill-layer TRUE)
		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object edge detail")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object edge detail")) 1)))
			)
			(gimp-image-add-layer img varDupLayer 3)
			(gimp-layer-set-name varDupLayer "object copy 2")
			(python-layer-fx-outer-glow (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "object copy 2")) '(0 0 0) 35 0 0 OVERLAY-MODE 0 100 TRUE FALSE)
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "object copy 2")))
			(gimp-item-set-name (car (gimp-image-get-layer-by-name img "object copy 2-outerglow")) "Object -outerglow")
			(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "Object -outerglow")) 0 3)
			(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "Object -outerglow")))
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "object copy 2-with-outerglow")))
		)
		; 

		
		
		;	
		; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object edge detail")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object edge detail")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-mode varDupLayer SOFTLIGHT-MODE)
			(gimp-layer-set-opacity varDupLayer 75)
			(gimp-layer-set-name varDupLayer "Object -softlight")
		)		
		; 
		
		

		;	
		; ************************************************************************************************************************************
		(gimp-edit-copy-visible img)
		
		(gimp-image-insert-layer img copy-visible-layer 0 3)
		(set! floating-selection (car (gimp-edit-paste copy-visible-layer 0)))
		(gimp-floating-sel-anchor floating-selection)

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "copy-visible")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "copy-visible")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-desaturate-full varDupLayer DESATURATE-LIGHTNESS)
			(plug-in-sharpen (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 30)
			(gimp-levels-stretch varDupLayer)
			(plug-in-mosaic (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 30 1 1 0.1 FALSE 0 0.35 TRUE TRUE 2 0 0)
			(gimp-layer-set-name varDupLayer "copy-visible -mosaic")
		)
		
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "copy-visible")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-desaturate-full varDupLayer DESATURATE-LIGHTNESS)
			(plug-in-sharpen (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 40)
			(gimp-levels-stretch varDupLayer)
			(plug-in-mosaic (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 22 1 1 0.1 FALSE 0 0.35 TRUE TRUE 1 0 0)
			(gimp-layer-set-name varDupLayer "copy-visible -mosaic small")
		)
		
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "copy-visible")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-desaturate-full varDupLayer DESATURATE-LIGHTNESS)
			(plug-in-sharpen (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 40)
			(gimp-levels-stretch varDupLayer)
			(plug-in-mosaic (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 11 1 1 0.1 FALSE 0 0.35 TRUE TRUE 1 0 0)
			(gimp-layer-set-name varDupLayer "copy-visible -mosaic xx small")
		)
		
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "copy-visible")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-desaturate-full varDupLayer DESATURATE-LIGHTNESS)
			(plug-in-sharpen (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 40)
			(gimp-levels-stretch varDupLayer)
			(plug-in-mosaic (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 56 1 1 0.1 FALSE 0 0.35 TRUE TRUE 1 0 0)
			(gimp-layer-set-name varDupLayer "copy-visible -mosaic xxl")
		)

		(gimp-by-color-select-full (car (gimp-image-get-layer-by-name img "copy-visible -mosaic")) '(68 68 68) 0 CHANNEL-OP-ADD FALSE FALSE 0 0 FALSE FALSE 0)
		(gimp-selection-shrink img 3)
		(gimp-selection-grow img 3)

		;;	
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "copy-visible")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "copy-visible")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(set! layer-mask (car (gimp-layer-create-mask varDupLayer ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img varDupLayer layer-mask)
			(gimp-selection-none img)
			(gimp-image-remove-layer-mask img varDupLayer MASK-APPLY)
			(gimp-layer-scale-full varDupLayer (* ImageWidth 1.12) (* ImageHeight 1.12) TRUE INTERPOLATION-CUBIC)
			(gimp-layer-resize-to-image-size varDupLayer)
			(gimp-layer-set-name varDupLayer "stones _1")
			(python-layer-fx-bevel-emboss RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "stones _1")) 1 65 0 6 0 120 36 0 '(255 255 255) SCREEN-MODE 74 '(0 0 0) MULTIPLY-MODE 74 0 FALSE "Pine" 100 100 FALSE TRUE)
			(python-layer-fx-bevel-emboss RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "stones _1")) 1 65 0 45 0 120 36 0 '(255 255 255) SCREEN-MODE 100 '(0 0 0) MULTIPLY-MODE 100 0 FALSE "Pine" 100 100 FALSE TRUE)
		)
		;; 
		
		(gimp-by-color-select-full (car (gimp-image-get-layer-by-name img "copy-visible -mosaic")) '(78 78 78) 0 CHANNEL-OP-ADD FALSE FALSE 0 0 FALSE FALSE 0)
		(gimp-selection-shrink img 3)
		(gimp-selection-grow img 4)
		
		;;	
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "stones _1")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "copy-visible")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(set! layer-mask (car (gimp-layer-create-mask varDupLayer ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img varDupLayer layer-mask)
			(gimp-selection-none img)
			(gimp-image-remove-layer-mask img varDupLayer MASK-APPLY)
			(gimp-layer-scale-full varDupLayer (* ImageWidth 1.1) (* ImageHeight 1.1) TRUE INTERPOLATION-CUBIC)
			(gimp-layer-translate varDupLayer -20 0)
			(gimp-layer-resize-to-image-size varDupLayer)
			(gimp-layer-set-name varDupLayer "stones _2")
			(python-layer-fx-bevel-emboss RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "stones _2")) 1 65 0 6 0 120 36 0 '(255 255 255) SCREEN-MODE 70 '(0 0 0) MULTIPLY-MODE 70 0 FALSE "Pine" 100 100 FALSE TRUE)
			(python-layer-fx-bevel-emboss RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "stones _2")) 1 65 0 45 0 120 36 0 '(255 255 255) SCREEN-MODE 100 '(0 0 0) MULTIPLY-MODE 100 0 FALSE "Pine" 100 100 FALSE TRUE)
			
		)
		;; 

		(gimp-by-color-select-full (car (gimp-image-get-layer-by-name img "copy-visible -mosaic small")) '(138 138 138) 2 CHANNEL-OP-ADD FALSE FALSE 0 0 FALSE FALSE 0)
		(gimp-selection-shrink img 2)
		(gimp-selection-grow img 3)

		;;	
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "stones _2")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "copy-visible")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(set! layer-mask (car (gimp-layer-create-mask varDupLayer ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img varDupLayer layer-mask)
			(gimp-selection-none img)
			(gimp-image-remove-layer-mask img varDupLayer MASK-APPLY)
			(gimp-layer-scale-full varDupLayer (* ImageWidth 1.08) (* ImageHeight 1.06) TRUE INTERPOLATION-CUBIC)
			(gimp-layer-translate varDupLayer -55 0)
			(gimp-layer-resize-to-image-size varDupLayer)
			(gimp-layer-set-name varDupLayer "stones _3")
			(python-layer-fx-bevel-emboss RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "stones _3")) 1 60 0 6 0 120 36 0 '(255 255 255) SCREEN-MODE 72 '(0 0 0) MULTIPLY-MODE 72 0 FALSE "Pine" 100 100 FALSE TRUE)
			(python-layer-fx-bevel-emboss RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "stones _3")) 1 60 0 45 0 120 36 0 '(255 255 255) SCREEN-MODE 100 '(0 0 0) MULTIPLY-MODE 100 0 FALSE "Pine" 100 100 FALSE TRUE)
			
		)
		;; 


		(gimp-by-color-select-full (car (gimp-image-get-layer-by-name img "copy-visible -mosaic xx small")) '(74 74 74) 0 CHANNEL-OP-ADD FALSE FALSE 0 0 FALSE FALSE 0)
		(gimp-selection-shrink img 1)
		(gimp-selection-grow img 2)

		;;	
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "stones _3")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "copy-visible")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(set! layer-mask (car (gimp-layer-create-mask varDupLayer ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img varDupLayer layer-mask)
			(gimp-selection-none img)
			(gimp-image-remove-layer-mask img varDupLayer MASK-APPLY)
			(gimp-layer-scale-full varDupLayer (* ImageWidth 1.04) (* ImageHeight 1.04) TRUE INTERPOLATION-CUBIC)
			(gimp-layer-translate varDupLayer -10 30)
			(gimp-layer-resize-to-image-size varDupLayer)
			(gimp-layer-set-name varDupLayer "stones _4")
			(python-layer-fx-bevel-emboss RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "stones _4")) 1 64 0 6 0 120 36 0 '(255 255 255) SCREEN-MODE 70 '(0 0 0) MULTIPLY-MODE 70 0 FALSE "Pine" 100 100 FALSE TRUE)
			(python-layer-fx-bevel-emboss RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "stones _4")) 1 64 0 45 0 120 36 0 '(255 255 255) SCREEN-MODE 100 '(0 0 0) MULTIPLY-MODE 100 0 FALSE "Pine" 100 100 FALSE TRUE)
			
		)
		;; 

		
		;;	
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "stones _4")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "stones _4")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-translate varDupLayer (-(/ ImageWidth 12)) (-(/ ImageHeight 40)))
			(gimp-layer-resize-to-image-size varDupLayer)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "brush-mask-scale 2")))
			(gimp-selection-invert img)
			(set! layer-mask (car (gimp-layer-create-mask varDupLayer ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img varDupLayer layer-mask)
			(gimp-selection-none img)
			(gimp-layer-set-name varDupLayer "stones _4b")
		)
		;; 


		(gimp-by-color-select-full (car (gimp-image-get-layer-by-name img "copy-visible -mosaic xxl")) '(42 42 42) 1 CHANNEL-OP-ADD FALSE FALSE 0 0 FALSE FALSE 0)
		(gimp-selection-shrink img 1)
		(gimp-selection-grow img 2)

		;;	
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "stones _4b")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "copy-visible")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(set! layer-mask (car (gimp-layer-create-mask varDupLayer ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img varDupLayer layer-mask)
			(gimp-selection-none img)
			(gimp-image-remove-layer-mask img varDupLayer MASK-APPLY)
			(gimp-layer-scale-full varDupLayer (* ImageWidth 1.32) (* ImageHeight 1.32) TRUE INTERPOLATION-CUBIC)
			(gimp-layer-translate varDupLayer 0 30)
			(gimp-layer-resize-to-image-size varDupLayer)
			(gimp-layer-set-name varDupLayer "stones _5")
			(python-layer-fx-bevel-emboss RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "stones _5")) 1 64 0 6 0 120 36 0 '(255 255 255) SCREEN-MODE 75 '(0 0 0) MULTIPLY-MODE 75 0 FALSE "Pine" 100 100 FALSE TRUE)
			(python-layer-fx-bevel-emboss RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "stones _5")) 1 64 0 45 0 120 36 0 '(255 255 255) SCREEN-MODE 100 '(0 0 0) MULTIPLY-MODE 100 0 FALSE "Pine" 100 100 FALSE TRUE)
			(plug-in-gauss RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "copy-visible")) 5 5 1)
		)
		;; 

		(gimp-by-color-select-full (car (gimp-image-get-layer-by-name img "copy-visible -mosaic xxl")) '(164 164 164) 1 CHANNEL-OP-ADD FALSE FALSE 0 0 FALSE FALSE 0)
		(gimp-selection-shrink img 3)
		(gimp-selection-grow img 2)

		;;	
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "stones _5")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "copy-visible")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(set! layer-mask (car (gimp-layer-create-mask varDupLayer ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img varDupLayer layer-mask)
			(gimp-selection-none img)
			(gimp-image-remove-layer-mask img varDupLayer MASK-APPLY)
			(gimp-layer-scale-full varDupLayer (* ImageWidth 1.14) (* ImageHeight 1.14) TRUE INTERPOLATION-CUBIC)
			(gimp-layer-translate varDupLayer -30 20)
			(gimp-layer-resize-to-image-size varDupLayer)
			(gimp-layer-set-name varDupLayer "stones _6")
			(python-layer-fx-bevel-emboss RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "stones _6")) 1 64 0 6 0 120 36 0 '(255 255 255) SCREEN-MODE 73 '(0 0 0) MULTIPLY-MODE 73 0 FALSE "Pine" 100 100 FALSE TRUE)
			(python-layer-fx-bevel-emboss RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "stones _6")) 1 64 0 45 0 120 36 0 '(255 255 255) SCREEN-MODE 100 '(0 0 0) MULTIPLY-MODE 100 0 FALSE "Pine" 100 100 FALSE TRUE)
		)
		;; 



		;;	
		;; ************************************************************************************************************************************
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "copy-visible -mosaic")))
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "copy-visible -mosaic small")))
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "copy-visible -mosaic xx small")))
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "copy-visible -mosaic xxl")))
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "copy-visible")))
		
		;; 
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "stones _6")))
		(let* (
				(varDupLayer7 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "stones _6")) 1)))
				(varDupLayer8 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "stones _5")) 1)))
				(varDupLayer9 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "stones _4")) 1)))
				(varDupLayer10 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "stones _3")) 1)))
				(varDupLayer11 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "stones _2")) 1)))
				(varDupLayer12 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "stones _1")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer9 0 -1)
			(gimp-layer-scale-full varDupLayer9 (* ImageWidth 1.7) (* ImageHeight 1.7) TRUE INTERPOLATION-CUBIC)
			(gimp-item-transform-flip-simple varDupLayer9 ORIENTATION-HORIZONTAL FALSE (/ ImageWidth 2))
			(gimp-layer-resize-to-image-size varDupLayer9)
			(gimp-layer-set-name varDupLayer9 "stones _9")

			(gimp-image-insert-layer img varDupLayer10 0 -1)
			(gimp-layer-scale-full varDupLayer10 (* ImageWidth 1.7) (* ImageHeight 1.7) TRUE INTERPOLATION-CUBIC)
			(gimp-item-transform-flip-simple varDupLayer10 ORIENTATION-HORIZONTAL FALSE (/ ImageWidth 2))
			(gimp-layer-resize-to-image-size varDupLayer10)
			(gimp-layer-set-name varDupLayer10 "stones _10")

			(gimp-image-insert-layer img varDupLayer11 0 -1)
			(gimp-layer-scale-full varDupLayer11 (* ImageWidth 1.6) (* ImageHeight 1.6) TRUE INTERPOLATION-CUBIC)
			(gimp-item-transform-flip-simple varDupLayer11 ORIENTATION-HORIZONTAL FALSE (/ ImageWidth 2))
			(gimp-layer-resize-to-image-size varDupLayer11)
			(gimp-layer-set-name varDupLayer11 "stones _11")
			
			(gimp-image-insert-layer img varDupLayer12 0 -1)
			(gimp-layer-scale-full varDupLayer12 (* ImageWidth 1.7) (* ImageHeight 1.7) TRUE INTERPOLATION-CUBIC)
			(gimp-item-transform-flip-simple varDupLayer12 ORIENTATION-HORIZONTAL FALSE (/ ImageWidth 2))
			(gimp-layer-resize-to-image-size varDupLayer12)
			(gimp-layer-set-name varDupLayer12 "stones _12")
			
			(gimp-image-insert-layer img varDupLayer7 0 -1)
			(gimp-layer-scale-full varDupLayer7 (* ImageWidth 1.6) (* ImageHeight 1.6) TRUE INTERPOLATION-CUBIC)
			(gimp-item-transform-flip-simple varDupLayer7 ORIENTATION-HORIZONTAL FALSE (/ ImageWidth 2))
			(gimp-layer-resize-to-image-size varDupLayer7)
			(plug-in-gauss RUN-NONINTERACTIVE img varDupLayer7 19 19 1)
			(gimp-layer-set-name varDupLayer7 "stones _7")
			
			(gimp-image-insert-layer img varDupLayer8 0 -1)
			(gimp-layer-scale-full varDupLayer8 (* ImageWidth 1.4) (* ImageHeight 1.4) TRUE INTERPOLATION-CUBIC)
			(gimp-item-transform-flip-simple varDupLayer8 ORIENTATION-HORIZONTAL FALSE (/ ImageWidth 2))
			(gimp-layer-resize-to-image-size varDupLayer8)
			(plug-in-gauss RUN-NONINTERACTIVE img varDupLayer8 22 22 1)
			(gimp-layer-set-name varDupLayer8 "stones _8")
			
			;; 
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "brush-mask-scale 2")))
			(gimp-selection-invert img)
			(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "stones _3")) ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "stones _3")) layer-mask)
			(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "stones _4")) ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "stones _4")) layer-mask)
			(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "stones _5")) ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "stones _5")) layer-mask)
			(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "stones _6")) ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "stones _6")) layer-mask)
			(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "stones _7")) ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "stones _7")) layer-mask)
			(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "stones _8")) ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "stones _8")) layer-mask)
			(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "stones _9")) ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "stones _9")) layer-mask)
			(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "stones _10")) ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "stones _10")) layer-mask)
			(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "stones _11")) ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "stones _11")) layer-mask)
			(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "stones _12")) ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "stones _12")) layer-mask)
			(gimp-selection-none img)
		)
		
		;;	
		;; ************************************************************************************************************************************
		(gimp-item-set-name stones-group "Stones Group")
		(gimp-layer-set-mode stones-group NORMAL-MODE)
		(gimp-layer-set-opacity stones-group 100)
		(gimp-image-insert-layer img stones-group 0 3)

		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "stones _1")) (car (gimp-image-get-layer-by-name img "Stones Group")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "stones _2")) (car (gimp-image-get-layer-by-name img "Stones Group")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "stones _3")) (car (gimp-image-get-layer-by-name img "Stones Group")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "stones _4")) (car (gimp-image-get-layer-by-name img "Stones Group")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "stones _4b")) (car (gimp-image-get-layer-by-name img "Stones Group")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "stones _5")) (car (gimp-image-get-layer-by-name img "Stones Group")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "stones _6")) (car (gimp-image-get-layer-by-name img "Stones Group")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "stones _7")) (car (gimp-image-get-layer-by-name img "Stones Group")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "stones _8")) (car (gimp-image-get-layer-by-name img "Stones Group")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "stones _9")) (car (gimp-image-get-layer-by-name img "Stones Group")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "stones _10")) (car (gimp-image-get-layer-by-name img "Stones Group")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "stones _11")) (car (gimp-image-get-layer-by-name img "Stones Group")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "stones _12")) (car (gimp-image-get-layer-by-name img "Stones Group")) 0)
		;;	
		;; ************************************************************************************************************************************
		
		

		;	
		; ************************************************************************************************************************************
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -glow (2)")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 4)
			(gimp-image-remove-layer-mask img varDupLayer MASK-APPLY)
			(gimp-layer-set-name varDupLayer "object inner cracks -beams")
			(plug-in-mblur (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "object inner cracks -beams")) 0 (/ ImageHeight 7) 90 (/ ImageWidth 2) (/ ImageHeight 2))
			(plug-in-mblur (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "object inner cracks -beams")) 0 (/ ImageHeight 26) -90 (/ ImageWidth 2) (/ ImageHeight 2))
		)
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -beams")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 4)
			(gimp-layer-set-name varDupLayer "object inner cracks -beams 2")
			(plug-in-mblur (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "object inner cracks -beams 2")) 0 (/ ImageHeight 4.5) 90 (/ ImageWidth 2) (/ ImageHeight 2))
			(gimp-image-merge-down img varDupLayer CLIP-TO-IMAGE)
		)
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -beams")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 4)
			(gimp-layer-set-mode varDupLayer LIGHTEN-ONLY-MODE)
			(gimp-layer-set-name varDupLayer "object inner cracks -beams (2)")
		)
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -beams (2)")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 4)
			(gimp-image-merge-down img varDupLayer EXPAND-AS-NECESSARY)
		)
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -beams (2)")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 4)
			(plug-in-gauss RUN-NONINTERACTIVE img varDupLayer 12 12 1)
			(gimp-image-merge-down img varDupLayer EXPAND-AS-NECESSARY)
		)
		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "object inner cracks -beams (2)")) DODGE-MODE)
		(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "object inner cracks -beams (2)")) 90)
		;; 
		
		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object outer cracks")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object outer cracks")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-scale-full varDupLayer (* ImageWidth 1.6) (* ImageHeight 1.6) TRUE INTERPOLATION-CUBIC)
			(plug-in-gauss RUN-NONINTERACTIVE img varDupLayer 6 6 1)
			(plug-in-gauss RUN-NONINTERACTIVE img varDupLayer 12 12 1)
			(gimp-layer-set-opacity varDupLayer 30)
			(gimp-layer-set-name varDupLayer "object outer cracks -wide")
		)
		
		
		;;		
		; ************************************************************************************************************************************
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -glow")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 3)
			(gimp-image-remove-layer-mask img varDupLayer MASK-APPLY)
			(gimp-layer-set-mode varDupLayer NORMAL)
			(gimp-selection-layer-alpha varDupLayer)
			(gimp-selection-grow img 3)
			(gimp-context-set-foreground '(0 0 0))
			(gimp-edit-fill varDupLayer FOREGROUND-FILL)
			(gimp-selection-none img)
			(gimp-layer-set-name varDupLayer "(tmp)")
			(plug-in-hsv-noise RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "(tmp)")) 7 60 255 255)
			(gimp-desaturate-full varDupLayer DESATURATE-LIGHTNESS)
			(plug-in-spread RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "(tmp)")) 3 3)	
		)
		; 	
		(gimp-item-set-name dots-layer-group "Dots Group")
		(gimp-layer-set-mode dots-layer-group NORMAL-MODE)
		(gimp-layer-set-opacity dots-layer-group 75)
		(gimp-image-insert-layer img dots-layer-group 0 7)
		
		(gimp-image-insert-layer img dots-layer dots-layer-group 0)
		(gimp-by-color-select-full (car (gimp-image-get-layer-by-name img "(tmp)")) '(137 137 137) 30 CHANNEL-OP-ADD FALSE FALSE 0 0 FALSE FALSE 0)
		(gimp-selection-grow img 2)
		(gimp-selection-feather img 6)
		(gimp-context-set-foreground '(255 255 255))
		(gimp-edit-fill dots-layer FOREGROUND-FILL)
		(gimp-selection-none img)
		(gimp-layer-scale-full dots-layer ImageWidth (* ImageHeight 1.2) TRUE INTERPOLATION-CUBIC)
		(gimp-layer-translate dots-layer 0 (-(/ (-(* ImageHeight 1.2) ImageHeight) 2)))
		(gimp-layer-resize-to-image-size dots-layer)
		;;	
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "(tmp)")))

		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "Dots")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-scale-full varDupLayer ImageWidth (* ImageHeight 1.13) TRUE INTERPOLATION-CUBIC)
			(gimp-layer-translate varDupLayer 0 (-(/ (-(* ImageHeight 1.13) ImageHeight) 2)))
			(plug-in-waves (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 5 360 20 0 FALSE)
			(plug-in-waves (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 5 260 10 0 FALSE)
			(plug-in-mblur (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 0 (/ ImageHeight 60) 90 (/ ImageWidth 2) (/ ImageHeight 2))
			(gimp-layer-translate varDupLayer 0 -60)
			(gimp-layer-resize-to-image-size varDupLayer)
			(gimp-layer-set-name varDupLayer "Dots Glow")
		)
			
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Dots Glow")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "Dots Glow")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-gauss RUN-NONINTERACTIVE img varDupLayer 5 5 1)
			(gimp-layer-set-name varDupLayer "Dots 3")
		)
		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Dots 3")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "Dots 3")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-gauss RUN-NONINTERACTIVE img varDupLayer 12 12 1)
			(gimp-layer-set-name varDupLayer "Dots 4")
		)
		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Dots 4")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "Dots 4")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-gauss RUN-NONINTERACTIVE img varDupLayer 18 18 1)
			(gimp-image-merge-down img varDupLayer EXPAND-AS-NECESSARY)
		)
		(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "Dots 4")) EXPAND-AS-NECESSARY)
		(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "Dots 3")) EXPAND-AS-NECESSARY)
		(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "Dots Glow")) 60)

		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "Dots")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-gauss RUN-NONINTERACTIVE img varDupLayer 18 18 1)
			(gimp-layer-translate varDupLayer -1 -1)
			(gimp-layer-resize-to-image-size varDupLayer)
			(gimp-layer-set-name varDupLayer "Dots Glow (1)")
		)	
		

		;
		; ************************************************************************************************************************************
		(python-layer-fx-inner-glow RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "base object")) '(0 0 0) 45 1 0 OVERLAY-MODE 1 0 45 FALSE)
		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "background-color")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "base object")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-name varDupLayer "base object 2")
			(python-layer-fx-outer-glow RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "base object 2")) '(0 0 0) 48 1 0 MULTIPLY-MODE 0 70 TRUE FALSE)
		)	
		
		(gimp-selection-feather img 2)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "base object")))
		(gimp-selection-shrink img 18)
		(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "object edge detail")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "object edge detail")) layer-mask)
		(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "Object -softlight")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "Object -softlight")) layer-mask)
		(gimp-selection-none img)


		(gimp-layer-set-name (car (gimp-image-get-layer-by-name img "base object-innerglow")) "Object -innerglow")
		(gimp-layer-set-name (car (gimp-image-get-layer-by-name img "base object")) "Object")
		(gimp-layer-set-name (car (gimp-image-get-layer-by-name img "base object 2-outerglow")) "Object -outerglow (2)")
		
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "Object -innerglow")) 0 19)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "Object")) 0 20)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "Object -outerglow (2)")) 0 21)

		
		(gimp-desaturate-full (car (gimp-image-get-layer-by-name img "Object")) DESATURATE-LIGHTNESS)
		(gimp-levels-stretch (car (gimp-image-get-layer-by-name img "Object")))
		;	
		; ************************************************************************************************************************************
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "base object 2-with-outerglow")))
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "base object-with-innerglow")))
		; 


		;;	
		;; ************************************************************************************************************************************
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "Object")) TRUE)	
		(set! object-layer-high-pass (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "Object")) 0)))
		(gimp-image-insert-layer img object-layer-high-pass 0 17)
		(gimp-layer-set-opacity object-layer-high-pass 100)
		(gimp-layer-set-name object-layer-high-pass "object (highPass)")
		(set! object-layer-high-pass-dupl (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object (highPass)")) 0)))
		(gimp-image-insert-layer img object-layer-high-pass-dupl 0 -1)
		(gimp-invert object-layer-high-pass-dupl)
		(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img object-layer-high-pass-dupl (/ ImageWidth 80) (/ ImageWidth 80) 1)
		(gimp-layer-set-opacity object-layer-high-pass-dupl 50)
		(gimp-image-merge-down img object-layer-high-pass-dupl CLIP-TO-BOTTOM-LAYER)
		(gimp-brightness-contrast (car (gimp-image-get-layer-by-name img "object (highPass)")) 0 90)
		(gimp-desaturate-full (car (gimp-image-get-layer-by-name img "object (highPass)")) DESATURATE-AVERAGE)
		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "object (highPass)")) OVERLAY-MODE)

		
		;;	
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "brush-mask-scale")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -glow (3)")) 1)))
				(varDupLayer2 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -glow (2)")) 1)))
				(varDupLayer3 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -glow")) 1)))
				(varDupLayer4 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -bevel-highlight")) 1)))
				(varDupLayer5 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -bevel-shadow")) 1)))
				(varDupLayer6 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -bevel")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer6 0 -1)
			(gimp-image-insert-layer img varDupLayer5 0 -1)
			(gimp-image-insert-layer img varDupLayer4 0 -1)
			(gimp-image-insert-layer img varDupLayer3 0 -1)
			(gimp-image-insert-layer img varDupLayer2 0 -1)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			
			(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 40 40 1)
			(gimp-layer-set-name varDupLayer "object inner cracks -glow (3) (tmp)")
			
			(gimp-image-remove-layer-mask img varDupLayer2 MASK-APPLY)
			(gimp-layer-set-name varDupLayer2 "object inner cracks -glow (2) (tmp)")			
			
			(gimp-image-remove-layer-mask img varDupLayer3 MASK-APPLY)
			(gimp-layer-set-name varDupLayer3 "object inner cracks -glow (tmp)")
			
			(gimp-layer-set-name varDupLayer4 "object inner cracks -bevel-highlight (tmp)")			
			(gimp-layer-set-name varDupLayer5 "object inner cracks -bevel-shadow (tmp)")
			
			(gimp-image-remove-layer-mask img varDupLayer6 MASK-APPLY)
			(gimp-layer-set-name varDupLayer6 "object inner cracks -bevel (tmp)")
			
			(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "object inner cracks -glow (3) (tmp)")) EXPAND-AS-NECESSARY)
			(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "object inner cracks -glow (2) (tmp)")) EXPAND-AS-NECESSARY)
			(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "object inner cracks -glow (tmp)")) EXPAND-AS-NECESSARY)
			(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "object inner cracks -bevel-highlight (tmp)")) EXPAND-AS-NECESSARY)
			(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "object inner cracks -bevel-shadow (tmp)")) EXPAND-AS-NECESSARY)
			(gimp-layer-set-name (car (gimp-image-get-layer-by-name img "object inner cracks -bevel (tmp)")) "object inner cracks -duplicate (set opacity !!)")
			(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "object inner cracks -duplicate (set opacity !!)")) 24)
			(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "object inner cracks -duplicate (set opacity !!)")) DODGE-MODE)
			(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "object inner cracks -duplicate (set opacity !!)")) 0 16)
		)
		;	

		; 	
		(gimp-item-set-name cracks-layer-group "Cracks")
		(gimp-layer-set-mode cracks-layer-group NORMAL-MODE)
		(gimp-layer-set-opacity cracks-layer-group 100)
		(gimp-image-insert-layer img cracks-layer-group 0 17)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "object inner cracks -duplicate (set opacity !!)")) (car (gimp-image-get-layer-by-name img "Cracks")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "object outer cracks")) (car (gimp-image-get-layer-by-name img "Cracks")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "object outer cracks -wide")) (car (gimp-image-get-layer-by-name img "Cracks")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "object inner cracks -bevel")) (car (gimp-image-get-layer-by-name img "Cracks")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "object inner cracks -bevel-shadow")) (car (gimp-image-get-layer-by-name img "Cracks")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "object inner cracks -bevel-highlight")) (car (gimp-image-get-layer-by-name img "Cracks")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "object inner cracks -glow")) (car (gimp-image-get-layer-by-name img "Cracks")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "object inner cracks -glow (2)")) (car (gimp-image-get-layer-by-name img "Cracks")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "object inner cracks -glow (3)")) (car (gimp-image-get-layer-by-name img "Cracks")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "Dots Group")) (car (gimp-image-get-layer-by-name img "Cracks")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "object inner cracks -beams")) (car (gimp-image-get-layer-by-name img "Cracks")) 0)
		

		;;	
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "bg_t_6")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 7)
			(gimp-context-set-foreground '(0 0 0))
			(gimp-selection-all img)
			(gimp-edit-fill varDupLayer FOREGROUND-FILL)
			(gimp-selection-shrink img (- ImageHeight (* ImageHeight 0.9)))
			(gimp-selection-feather img (- ImageHeight (* ImageHeight 0.92)))
			(gimp-selection-invert img)
			(set! layer-mask (car (gimp-layer-create-mask varDupLayer ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img varDupLayer layer-mask)
			(gimp-selection-none img)
			(plug-in-gauss RUN-NONINTERACTIVE img (car (gimp-layer-get-mask varDupLayer)) (- ImageHeight (* ImageHeight 0.92)) (- ImageHeight (* ImageHeight 0.92)) 1)
			(plug-in-gauss RUN-NONINTERACTIVE img (car (gimp-layer-get-mask varDupLayer)) (- ImageHeight (* ImageHeight 0.94)) (- ImageHeight (* ImageHeight 0.94)) 1)
			(gimp-layer-set-opacity varDupLayer 75)
			(gimp-layer-set-name varDupLayer "Darken Picture Edges")
		)
		
		;;	
		(gimp-item-set-name object-brush-layer-group "Brush Object")
		(gimp-layer-set-mode object-brush-layer-group NORMAL-MODE)
		(gimp-layer-set-opacity object-brush-layer-group 100)
		(gimp-image-insert-layer img object-brush-layer-group 0 9)
		
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "Object -outerglow (2)")) (car (gimp-image-get-layer-by-name img "Brush Object")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "Object")) (car (gimp-image-get-layer-by-name img "Brush Object")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "Object -innerglow")) (car (gimp-image-get-layer-by-name img "Brush Object")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "object edge detail")) (car (gimp-image-get-layer-by-name img "Brush Object")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "Object -softlight")) (car (gimp-image-get-layer-by-name img "Brush Object")) 0)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "object (highPass)")) (car (gimp-image-get-layer-by-name img "Brush Object")) 0)
		;; 


		;;	
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "brush-mask-scale")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -beams (2)")) 1)))
				(varDupLayer2 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -beams")) 1)))
				(varDupLayer3 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -glow (3)")) 1)))
				(varDupLayer4 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -glow (2)")) 1)))
				(varDupLayer5 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -glow")) 1)))
				(varDupLayer6 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -bevel-highlight")) 1)))
				(varDupLayer7 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -bevel-shadow")) 1)))
				(varDupLayer8 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object inner cracks -bevel")) 1)))
				(varDupLayer9 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object outer cracks")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer9 0 -1)
			(gimp-image-insert-layer img varDupLayer8 0 -1)
			(gimp-image-insert-layer img varDupLayer7 0 -1)
			(gimp-image-insert-layer img varDupLayer6 0 -1)
			(gimp-image-insert-layer img varDupLayer5 0 -1)
			(gimp-image-insert-layer img varDupLayer4 0 -1)
			(gimp-image-insert-layer img varDupLayer3 0 -1)
			(gimp-image-insert-layer img varDupLayer2 0 -1)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			
			(gimp-layer-set-name varDupLayer "object inner cracks -beams (2) (tmp)")
			(gimp-layer-set-name varDupLayer2 "object inner cracks -beams (tmp)")
			
			(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer3 40 40 1)
			(gimp-layer-set-name varDupLayer3 "object inner cracks -glow (3) (tmp)")
			
			(gimp-image-remove-layer-mask img varDupLayer4 MASK-APPLY)
			(gimp-layer-set-name varDupLayer4 "object inner cracks -glow (2) (tmp)")
			
			(gimp-image-remove-layer-mask img varDupLayer5 MASK-APPLY)
			(gimp-layer-set-name varDupLayer5 "Cracks -shine (tmp)")
			
			(gimp-layer-set-name varDupLayer6 "object inner cracks -bevel-highlight (tmp)")
			(gimp-layer-set-name varDupLayer7 "object inner cracks -bevel-shadow (tmp)")
			
			(gimp-image-remove-layer-mask img varDupLayer8 MASK-APPLY)
			(gimp-layer-set-name varDupLayer8 "object inner cracks -bevel (tmp)")
			
			(gimp-image-remove-layer-mask img varDupLayer9 MASK-APPLY)
			(gimp-layer-set-name varDupLayer9 "object outer cracks (tmp)")
		)	

		;; 
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "Stones Group")) FALSE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "object inner cracks -beams (2)")) FALSE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "Object -outerglow")) FALSE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "Cracks")) FALSE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "Texture Group")) FALSE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "Brush Object")) FALSE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "Darken Picture Edges")) FALSE)
		(gimp-item-set-visible fill-layer FALSE)
		
		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object inner cracks -beams (2) (tmp)")))
		(gimp-image-merge-visible-layers img CLIP-TO-IMAGE)
		
		(gimp-layer-set-name (car (gimp-image-get-layer-by-name img "object outer cracks (tmp)")) "Dots Glow xxl")
		(gimp-layer-scale-full (car (gimp-image-get-layer-by-name img "Dots Glow xxl")) (* ImageWidth 1.88) (* ImageHeight 1.88) TRUE INTERPOLATION-CUBIC)
		
		;; 
		(plug-in-iwarp RUN-INTERACTIVE img (car (gimp-image-get-layer-by-name img "Dots Glow xxl")))
		
		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "Dots Glow xxl")) DODGE-MODE)
		(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "Dots Glow xxl")) 25 25 1)
		(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "Dots Glow xxl")) 48 48 1)
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "Dots Glow xxl")) 0 6)
		(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "Dots Glow xxl")))
		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Dots Glow xxl")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "Dots Glow xxl")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			;; 
			(gimp-item-transform-flip-simple varDupLayer ORIENTATION-HORIZONTAL FALSE (/ ImageWidth 2))
			(gimp-item-transform-flip-simple varDupLayer ORIENTATION-VERTICAL FALSE (/ ImageWidth 2))
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "Dots Glow xxl")))
			(set! layer-mask (car (gimp-layer-create-mask varDupLayer ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img varDupLayer layer-mask)
			(gimp-selection-none img)
			(gimp-layer-resize-to-image-size varDupLayer)
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "Dots Glow xxl")))
			(gimp-layer-set-name varDupLayer "Dots Glow xxl")
		)



		; 
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "Stones Group")) TRUE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "object inner cracks -beams (2)")) TRUE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "Object -outerglow")) TRUE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "Cracks")) TRUE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "Texture Group")) TRUE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "Brush Object")) TRUE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "Darken Picture Edges")) TRUE)
		(gimp-item-set-visible fill-layer TRUE)	

		(gimp-edit-copy-visible img)
		(gimp-image-insert-layer img copy-visible-layer2 0 3)
		(set! floating-selection (car (gimp-edit-paste copy-visible-layer2 0)))
		(gimp-floating-sel-anchor floating-selection)
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Layer 9")))
		(gimp-desaturate-full (car (gimp-image-get-layer-by-name img "Layer 9")) DESATURATE-LIGHTNESS)
		(gimp-levels-stretch (car (gimp-image-get-layer-by-name img "Layer 9")))

		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "Object")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-by-color-select-full (car (gimp-image-get-layer-by-name img "Layer 9")) '(250 250 250) 80 CHANNEL-OP-ADD TRUE TRUE 2 2 TRUE FALSE SELECT-CRITERION-COMPOSITE)
			(set! layer-mask (car (gimp-layer-create-mask varDupLayer ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img varDupLayer layer-mask)
			(gimp-selection-none img)
			(gimp-layer-set-mode varDupLayer SCREEN-MODE)
			(gimp-layer-set-opacity varDupLayer 50)
			(gimp-layer-set-name varDupLayer "Layer 10")
		)
		
		;	
		; ************************************************************************************************************************************
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "Layer 9")))
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "brush-mask-scale 2")))
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "brush-mask-scale")))

		
		(gimp-context-set-foreground '(41 41 41))
		(gimp-edit-fill fill-layer FOREGROUND-FILL)

		;;
		(gimp-selection-none img)

		;;
		(gimp-palette-set-background old-bg)
		(gimp-palette-set-foreground old-fg)
		(if (= inUndoMode TRUE) (begin (gimp-image-undo-group-end img)) )

		(gimp-displays-flush)
		;;	END....
	)
)