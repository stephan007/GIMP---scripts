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
;;	v0.01 Code Art!; Gimp v2.8.22																		;;
;;	(de)	http://www.3d-hobby-art.de/news/210-gimp-skript-fu-glow-art.html							;;
;;	(eng)	http://www.3d-hobby-art.de/en/blog/211-gimp-script-fu-glow-art.html							;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(script-fu-register
	"script-fu-glowart"																		;func name
	"Glow Art! ..."																			;menu label
	"Glow Art! Gimp Script Turns your photo into a masterpiece of an Epic Glow art."		;desc
	"Stephan W."
	"Stephan W.; (c) 2017, 3d-hobby-art.de"													;;	copyright notice
	"October 27, 2017"																		;;	date created
	"RGBA, RGB"																				;;	image type that the script works on
	SF-IMAGE		"Image"						0
	SF-DRAWABLE		"The layer"					0
	SF-OPTION		_"Language"					'("English (en_GB)" "German (de_DE)")		;;	choose language
	SF-TOGGLE		"Run Interactive Mode?"		FALSE
	SF-TOGGLE		"Undo Mode?"				FALSE
)
(script-fu-menu-register "script-fu-glowart" "<Image>/Script-Fu/Glow Art! Effect")

(define (script-fu-glowart img drawable inLanguage inRunMode inUndoMode)
	
	
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
	
	
	;; error massage
	(define (gimp-message-and-quit message)
		(let  
			;; get current handler
			((old-handler (car (gimp-message-get-handler))) )
			(gimp-message-set-handler MESSAGE-BOX)
			(gimp-message message)
			;; reset handler
			(gimp-message-set-handler old-handler)
			(quit)
		)
	)
	

	(let* ( 
			(bg-layer (car (gimp-image-get-layer-by-name img "background")))
			(brush-layer (car (gimp-image-get-layer-by-name img "brush")))
			
			(new-layer-marker (car (gimp-layer-new img 100 100 RGBA-IMAGE "marker (tmp)" 100 NORMAL)))
			
			(ImageWidth  (car (gimp-image-width  img)))
			(ImageHeight (car (gimp-image-height img)))
			(old-bg (car (gimp-context-get-background)))
			(old-fg (car (gimp-context-get-foreground)))
			
			(fill-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "background-color" 100 NORMAL)))
			(fill-black-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "black-bg" 100 NORMAL)))
			(noise-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "noise" 80 HARDLIGHT-MODE)))
			
			(cracks-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "cracks" 100 NORMAL)))
			(clouds-diff-layer (car (gimp-layer-new img ImageWidth ImageHeight (car (gimp-drawable-type-with-alpha drawable)) "clouds diff" 100 DIFFERENCE-MODE)))
			(layer-mask 0)
			
			(object-layer-high-pass 0)
			(object-layer-high-pass-dupl 0)
			
			(hue-saturation-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "Hue/Saturation" 100 SCREEN-MODE)))
			(hue-saturation-layer-mask 0)
			
			(brightness-contrast-layer 0)
			
			(softlight-layer 0)
			
			(floating-selection 0)
			(seed 0)
		)

		;; error handling
		(if  ( = (car (gimp-image-get-layer-by-name img "background")) -1)
			(gimp-message-and-quit "There is no \"background\" layer! Tutorial - please read. \n Keine \"background\" -Ebene gefunden! Bitte lesen Sie mein Tutorial.")
		)
		(if  ( = (car (gimp-image-get-layer-by-name img "brush")) -1)
			(gimp-message-and-quit "There is no \"brush\" layer! Tutorial - please read. \n Keine \"brush\" -Ebene gefunden! Bitte lesen Sie mein Tutorial.")
		)
		(if  ( = (car (gimp-procedural-db-proc-exists "python-layer-fx-gradient-overlay")) FALSE)
			(gimp-message-and-quit "\"LayerFX\" (Python-Fu) for Gimp 2.8 not installed!! Tutorial - please read. \n \"LayerFX\" (Python-Fu) für Gimp 2.8 nicht installiert. Bitte lesen Sie mein Tutorial.")
		)
		
		
		;; set seed - random numbers....
		(set! seed (if (number? seed) seed (realtime)))

		;; Undo Mode?
		(if (= inUndoMode TRUE) (begin (gimp-image-undo-group-start img) ) )
		(if (= inUndoMode FALSE) (begin (gimp-image-undo-disable img)) )
		
		(gimp-context-push)


		(gimp-context-set-foreground '(0 0 0))
		(gimp-context-set-background '(255 255 255))
		;; start...
		
		(plug-in-autocrop-layer RUN-NONINTERACTIVE img brush-layer)
		
		;;	marker
		;; ************************************************************************************************************************************
		(gimp-image-add-layer img new-layer-marker 0)
		(gimp-image-set-active-layer img new-layer-marker)
		(gimp-context-set-background '(245 0 0))
		(gimp-edit-fill new-layer-marker BACKGROUND-FILL)
		
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
				
				(gimp-layer-set-offsets new-layer-marker (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)))
		)


		;;	Background Color
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img new-layer-marker)
		(gimp-image-insert-layer img fill-layer 0 -1)
		(gimp-image-set-active-layer img fill-layer)
		(gimp-context-set-foreground '(0 0 0))
		(gimp-edit-fill fill-layer FOREGROUND-FILL)

		;;	Layer1
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img new-layer-marker)
		(let* (
				(varDupLayer (car (gimp-layer-copy bg-layer 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-item-set-visible varDupLayer TRUE)
			(gimp-selection-layer-alpha brush-layer)
			(gimp-selection-invert img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(gimp-layer-set-name varDupLayer "layer1")
		);; END layer1
		
		;;	"bg light" layer (gradient fill round)
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer1")))
		(let* (
				(base-x 0)
				(base-y 0)
				(base-layer (get-base-layer new-layer-marker))
				(base-width (car (gimp-image-width  img)))
				(base-height (car (gimp-image-height img)))
				(varDupLayer (car (gimp-layer-copy bg-layer 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-context-set-foreground '(255 255 255))
			(set! base-x (car  (gimp-drawable-offsets base-layer)))
			(set! base-y (cadr (gimp-drawable-offsets base-layer)))
			(set! base-width  (car (gimp-drawable-width  base-layer)))
			(set! base-height (car (gimp-drawable-height base-layer)))
			(python-layer-fx-gradient-overlay RUN-NONINTERACTIVE img varDupLayer (if (= inLanguage 0) "FG to Transparent" (if (= inLanguage 1) "VG nach Transparent")) GRADIENT-RADIAL REPEAT-NONE FALSE 100 NORMAL-MODE (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)) 90 (* (car (gimp-drawable-height varDupLayer)) 0.95) FALSE)
			(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "background copy-gradient" (if (= inLanguage 1) "background-Kopie-gradient")) )) 0 -1)
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "background copy-with-gradient" (if (= inLanguage 1) "background-Kopie-with-gradient")) )))
			(gimp-layer-set-name (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "background copy-gradient" (if (= inLanguage 1) "background-Kopie-gradient")) )) "bg light")
		);; END "bg light" layer (gradient fill round)


		;;	"noise" layer
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "bg light")))
		
		(gimp-image-insert-layer img noise-layer 0 -1)
		(gimp-image-set-active-layer img noise-layer)
		(gimp-context-set-foreground '(0 0 0))
		(gimp-edit-fill noise-layer FOREGROUND-FILL)
		(plug-in-rgb-noise RUN-NONINTERACTIVE img noise-layer FALSE FALSE 0.3 0.3 0.3 0);; END "noise" layer


		;;	Cracks (difference clouds)
		;; ************************************************************************************************************************************
		(gimp-image-add-layer img cracks-layer 0)
		(gimp-context-set-foreground '(0 0 0))
		(gimp-edit-fill cracks-layer FOREGROUND-FILL)
		(gimp-image-set-active-layer img cracks-layer)
		(set! seed (if (number? seed) seed (realtime)))
		(plug-in-solid-noise RUN-INTERACTIVE img cracks-layer TRUE FALSE seed 14 15.5 15.5)
		
		(gimp-image-add-layer img clouds-diff-layer 0)
		(gimp-drawable-fill clouds-diff-layer TRANSPARENT-FILL)		
		
		(plug-in-solid-noise RUN-INTERACTIVE img clouds-diff-layer TRUE FALSE seed 14 15.6 15.6)
		(gimp-image-merge-down img clouds-diff-layer EXPAND-AS-NECESSARY)

		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "cracks")) SOFTLIGHT-MODE);; END Cracks (difference clouds)

		
		;;	cracks-mask layer (gradient fill)
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "cracks")))
		(let* (
				(base-x 0)
				(base-y 0)
				(base-layer (get-base-layer new-layer-marker))
				(base-width (car (gimp-image-width  img)))
				(base-height (car (gimp-image-height img)))
				(varDupLayer (car (gimp-layer-copy bg-layer 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-context-set-foreground '(255 255 255))
			(gimp-context-set-background '(0 0 0))
			(set! base-x (car  (gimp-drawable-offsets base-layer)))
			(set! base-y (cadr (gimp-drawable-offsets base-layer)))
			(set! base-width  (car (gimp-drawable-width  base-layer)))
			(set! base-height (car (gimp-drawable-height base-layer)))
			(python-layer-fx-gradient-overlay RUN-NONINTERACTIVE img varDupLayer (if (= inLanguage 0) "FG to BG (RGB)" (if (= inLanguage 1) "VG nach HG (RGB)")) GRADIENT-RADIAL REPEAT-NONE FALSE 100 NORMAL-MODE (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)) 90 (* (car (gimp-drawable-height varDupLayer)) 2.95) FALSE)
			(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "background copy-gradient" (if (= inLanguage 1) "background-Kopie-gradient")) )) 0 -1)
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "background copy-with-gradient" (if (= inLanguage 1) "background-Kopie-with-gradient")) )))
			(gimp-layer-set-name (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "background copy-gradient" (if (= inLanguage 1) "background-Kopie-gradient")) )) "cracks-mask")
			(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "cracks-mask")) MULTIPLY-MODE)
		);; END cracks-mask layer (gradient fill)


		;;	"fading effect 3" layer
		; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "cracks-mask")))
		(let* (
				(varDupLayer (car (gimp-layer-copy fill-layer 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-selection-all img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-layer-alpha brush-layer)
			(gimp-context-set-foreground '(255 255 255))
			(gimp-edit-fill varDupLayer FOREGROUND-FILL)
			(gimp-selection-none img)
			(plug-in-gauss RUN-NONINTERACTIVE img varDupLayer 38 38 1)
			(gimp-layer-set-opacity varDupLayer 60)
			(gimp-layer-set-mode varDupLayer SOFTLIGHT-MODE)
			(gimp-layer-set-name varDupLayer "fading effect 3")
		);; END "fading effect 3" layer


		;;	"fading effect 2" layer
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "fading effect 3")))
		(let* (
				(base-x 0)
				(base-y 0)
				(base-layer (get-base-layer new-layer-marker))
				(base-width (car (gimp-image-width  img)))
				(base-height (car (gimp-image-height img)))
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(set! base-x (car  (gimp-drawable-offsets base-layer)))
			(set! base-y (cadr (gimp-drawable-offsets base-layer)))
			(set! base-width  (car (gimp-drawable-width  base-layer)))
			(set! base-height (car (gimp-drawable-height base-layer)))
			(gimp-selection-all img)
			(gimp-edit-clear varDupLayer)
			(gimp-context-set-feather 25)
			(gimp-selection-layer-alpha brush-layer)
			(gimp-selection-shrink img 25)
			(gimp-context-set-foreground '(0 0 0))
			(gimp-edit-fill varDupLayer FOREGROUND-FILL)
			(gimp-layer-set-mode varDupLayer NORMAL-MODE)
			(gimp-layer-set-opacity varDupLayer 100)
			(gimp-selection-none img)
			(plug-in-gauss RUN-NONINTERACTIVE img varDupLayer 34 34 1)
			(gimp-layer-set-name varDupLayer "fading effect 2")
			
			(plug-in-mblur RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "fading effect 2")) LINEAR (/ (car (gimp-drawable-height varDupLayer)) 20) 90 (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)))
			(gimp-layer-translate (car (gimp-image-get-layer-by-name img "fading effect 2")) 0 (/ (/ (car (gimp-drawable-height varDupLayer)) 20) 4) )
		);; END "fading effect 2" layer

		
		;;	"fading effect 1" layer
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "fading effect 2")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer1")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-gauss RUN-NONINTERACTIVE img varDupLayer 42 42 1)
			(gimp-layer-set-opacity varDupLayer 70)
			(gimp-layer-set-name varDupLayer "fading effect 1")
		);; END "fading effect 1" layer


		;;	Brightness/Contrast
		;; ************************************************************************************************************************************
		(gimp-edit-copy-visible img)
		(set! brightness-contrast-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "Brightness/Contrast 001" 100 NORMAL)))
		(gimp-image-insert-layer img brightness-contrast-layer 0 0)		
		(set! floating-selection (car (gimp-edit-paste brightness-contrast-layer 0)))
		(gimp-floating-sel-anchor floating-selection)
		(gimp-brightness-contrast (car (gimp-image-get-layer-by-name img "Brightness/Contrast 001")) 15 10)
		(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "Brightness/Contrast 001")) 25)
		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "Brightness/Contrast 001")) OVERLAY-MODE) ;; END Brightness/Contrast


		;;	"layer2 (tmp)" (mask for fading effect 2)
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Brightness/Contrast 001")))
		(let* (
				(varDupLayer (car (gimp-layer-copy bg-layer 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-context-set-foreground '(0 0 0))
			(python-layer-fx-gradient-overlay RUN-NONINTERACTIVE img varDupLayer (if (= inLanguage 0) "FG to Transparent" (if (= inLanguage 1) "VG nach Transparent")) GRADIENT-LINEAR REPEAT-NONE TRUE 100 NORMAL-MODE (/ ImageWidth 2) (/ ImageHeight 2) 90 (* (car (gimp-drawable-height varDupLayer)) 0.95) FALSE)
			(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "background copy-gradient" (if (= inLanguage 1) "background-Kopie-gradient")) )) 0 -1)
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "background copy-with-gradient" (if (= inLanguage 1) "background-Kopie-with-gradient")) )))
			(gimp-layer-set-name (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "background copy-gradient" (if (= inLanguage 1) "background-Kopie-gradient")) )) "layer2 (tmp)")
			(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer2 (tmp)")) FALSE)
		);; END "layer2 (tmp)" (mask for fading effect 2)


		;;	add "fading effect 2" mask
		;; ************************************************************************************************************************************
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer2 (tmp)")))
		(gimp-selection-invert img)
		(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "fading effect 2")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "fading effect 2")) layer-mask)
		(gimp-selection-none img) ;; END add "fading effect 2" mask


		;;	"bg light (wide)" layer
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Brightness/Contrast 001")))
		(let* (
				(base-x 0)
				(base-y 0)
				(base-layer (get-base-layer new-layer-marker))
				(base-width (car (gimp-image-width  img)))
				(base-height (car (gimp-image-height img)))
				(varDupLayer (car (gimp-layer-copy bg-layer 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-context-set-foreground '(255 255 255))
			(gimp-context-set-background '(0 0 0))
			(set! base-x (car  (gimp-drawable-offsets base-layer)))
			(set! base-y (cadr (gimp-drawable-offsets base-layer)))
			(set! base-width  (car (gimp-drawable-width  base-layer)))
			(set! base-height (car (gimp-drawable-height base-layer)))
			(python-layer-fx-gradient-overlay RUN-NONINTERACTIVE img varDupLayer "Rays small- 3d-hobby-art.de" GRADIENT-LINEAR REPEAT-NONE FALSE 80 SCREEN-MODE (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)) 0 (* (car (gimp-drawable-width brush-layer)) 0.75) FALSE)
			(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "background copy-gradient" (if (= inLanguage 1) "background-Kopie-gradient")) )) 0 1)
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "background copy-with-gradient" (if (= inLanguage 1) "background-Kopie-with-gradient")) )))
			(gimp-layer-set-name (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "background copy-gradient" (if (= inLanguage 1) "background-Kopie-gradient")) )) "bg light (wide)")
			(plug-in-gauss RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "bg light (wide)")) 80 80 1)
		);; END bg light (wide)

		
		;;	"bg light (small)" layer
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "bg light (wide)")))
		(let* (
				(base-x 0)
				(base-y 0)
				(base-layer (get-base-layer new-layer-marker))
				(base-width (car (gimp-image-width  img)))
				(base-height (car (gimp-image-height img)))
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "bg light (wide)")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(set! base-x (car  (gimp-drawable-offsets base-layer)))
			(set! base-y (cadr (gimp-drawable-offsets base-layer)))
			(set! base-width  (car (gimp-drawable-width  base-layer)))
			(set! base-height (car (gimp-drawable-height base-layer)))
			(python-layer-fx-gradient-overlay RUN-NONINTERACTIVE img varDupLayer "Rays - 3d-hobby-art.de" GRADIENT-LINEAR REPEAT-NONE FALSE 100 SCREEN-MODE (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)) 0 (* (car (gimp-drawable-width brush-layer)) 0.5) FALSE)
			(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "bg light (wide) copy-gradient" (if (= inLanguage 1) "bg light (wide)-Kopie-gradient")) )) 0 1)
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "bg light (wide) copy-with-gradient" (if (= inLanguage 1) "bg light (wide)-Kopie-with-gradient")) )))
			(gimp-layer-set-name (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "bg light (wide) copy-gradient" (if (= inLanguage 1) "bg light (wide)-Kopie-gradient")) )) "bg light (small)")
			(plug-in-gauss RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "bg light (small)")) 60 60 1)
		);; END bg light (small)
		
		;;	bg light (round)
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Brightness/Contrast 001")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "bg light")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-opacity varDupLayer 60)
			(gimp-layer-set-name varDupLayer "bg light (round)")
		);; END bg light (round)

		;;	layer3 (tmp) (mask for "bg light (wide)")
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "bg light (small)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy bg-layer 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-context-set-foreground '(0 0 0))
			(python-layer-fx-gradient-overlay RUN-NONINTERACTIVE img varDupLayer (if (= inLanguage 0) "FG to Transparent" (if (= inLanguage 1) "VG nach Transparent")) GRADIENT-LINEAR REPEAT-NONE FALSE 100 NORMAL-MODE (/ ImageWidth 2) (/ ImageHeight 2) 90 (* (car (gimp-drawable-height varDupLayer)) 0.9) FALSE)
			(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "background copy-gradient" (if (= inLanguage 1) "background-Kopie-gradient")) )) 0 1)
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "background copy-with-gradient" (if (= inLanguage 1) "background-Kopie-with-gradient")) )))
			(gimp-layer-set-name (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "background copy-gradient" (if (= inLanguage 1) "background-Kopie-gradient")) )) "layer3 (tmp)")
			(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer3 (tmp)")) FALSE)
		);; END layer3 (tmp)

		;;	layer3 (tmp) copy (mask for "bg light (small)")
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer3 (tmp)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-scale-full varDupLayer ImageWidth (* ImageHeight 1.3) TRUE INTERPOLATION-CUBIC)
			(gimp-layer-translate varDupLayer 0 (/ (-(* ImageHeight 1.2) ImageHeight) 2))
			(gimp-layer-set-name varDupLayer "layer3 (tmp) copy")
		);; END layer3 (tmp) copy (mask for "bg light (small)")

		
		;;	add "bg light (wide)" mask
		;; ************************************************************************************************************************************
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer3 (tmp)")))
		(gimp-selection-invert img)
		(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "bg light (wide)")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "bg light (wide)")) layer-mask)
		(gimp-selection-none img) ;; END add "bg light (wide)" mask

		;;	add "bg light (round)" mask
		;; ************************************************************************************************************************************
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer3 (tmp)")))
		(gimp-selection-invert img)
		(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "bg light (round)")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "bg light (round)")) layer-mask)
		(gimp-selection-none img) ;; END add "bg light (round)" mask

		;;	add "bg light (small)" mask
		;; ************************************************************************************************************************************
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer3 (tmp) copy")))
		(gimp-selection-invert img)
		(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "bg light (small)")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "bg light (small)")) layer-mask)
		(gimp-selection-none img) ;; END add "bg light (small)" mask

		
		;;	add fading-mask, +mask layer3 (tmp)
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "bg light (small)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer1")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-context-set-background '(0 0 0))
			(gimp-selection-all img)
			(gimp-edit-fill varDupLayer BACKGROUND-FILL)
			(gimp-selection-none img)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer3 (tmp)")))
			(set! layer-mask (car (gimp-layer-create-mask varDupLayer ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img varDupLayer layer-mask)
			(gimp-selection-none img)
			(gimp-layer-scale-full varDupLayer ImageWidth (* ImageHeight 1.8) TRUE INTERPOLATION-CUBIC)
			(gimp-layer-translate varDupLayer 0 (- (/ (-(* ImageHeight 1.75) ImageHeight) 2)))
			(gimp-layer-set-name varDupLayer "fading-mask")		
		);; END add fading-mask, +mask layer3 (tmp)

		;;	add fading-mask mask to selection
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "fading-mask")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "fading-mask")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-image-remove-layer-mask img varDupLayer MASK-APPLY)
			(gimp-layer-set-name varDupLayer "fading-mask copy")		
		)

		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "fading-mask copy")))
		(gimp-selection-invert img)
		(gimp-context-set-background '(0 0 0))
		(gimp-edit-fill (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "fading-mask")))) BACKGROUND-FILL)
		(gimp-edit-fill (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "fading-mask")))) BACKGROUND-FILL)
		(gimp-selection-none img)
		
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "fading-mask copy")))
		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "fading-mask")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "fading-mask")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-image-remove-layer-mask img varDupLayer MASK-APPLY)
			(gimp-layer-set-name varDupLayer "fading-mask copy")		
		)

		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "fading-mask copy")))
		(gimp-selection-invert img)
		(gimp-context-set-background '(0 0 0))
		(gimp-edit-fill (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "fading-mask")))) BACKGROUND-FILL)
		(gimp-selection-none img)
		
		
		(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "fading-mask")) 90)
		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "fading-mask")) DARKEN-ONLY-MODE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "fading-mask copy")) FALSE);; END add fading-mask mask to selection
		
		
		;;	High pass filter
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "fading-mask")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer1")) 1)))
				(varDupLayer2 (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer1")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer2 0 -1)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-name varDupLayer "object (highPass)")
			(set! object-layer-high-pass-dupl (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object (highPass)")) 0)))
			(gimp-image-insert-layer img object-layer-high-pass-dupl 0 -1)
			(gimp-invert object-layer-high-pass-dupl)
			(plug-in-gauss RUN-NONINTERACTIVE img object-layer-high-pass-dupl (/ ImageWidth 80) (/ ImageWidth 80) 1)
			(gimp-layer-set-opacity object-layer-high-pass-dupl 50)
			(gimp-image-merge-down img object-layer-high-pass-dupl CLIP-TO-BOTTOM-LAYER)
			(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "object (highPass)")) OVERLAY-MODE)
			(gimp-layer-set-name varDupLayer2 "object")
			
			; add masks "object (highPass)"
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer3 (tmp)")))
			(gimp-selection-invert img)
			(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "object (highPass)")) ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "object (highPass)")) layer-mask)
			(gimp-selection-none img)
			; fill white "object (highPass)"
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer3 (tmp)")))
			(gimp-selection-invert img)
			(gimp-context-set-background '(255 255 255))
			(gimp-edit-fill (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "object (highPass)")))) BACKGROUND-FILL)
			(gimp-selection-none img)
			
			;; add copy masks from "object (highPass)" layer
			(gimp-edit-copy (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "object (highPass)")))))
			(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "object")) ADD-WHITE-MASK)))
			(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "object")) layer-mask)
			(set! floating-selection (car (gimp-edit-paste layer-mask 0)))
			(gimp-floating-sel-anchor floating-selection)
		);; END High pass filter	
		
		
		;;	add layer4 (tmp)
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object (highPass)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer1")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-selection-all img)
			(gimp-edit-clear varDupLayer)
			(gimp-context-set-background '(0 0 0))
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "fading effect 2")))
			(gimp-edit-fill varDupLayer BACKGROUND-FILL)
			(gimp-selection-none img)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "fading-mask copy")))
			(gimp-edit-clear varDupLayer)
			(gimp-edit-clear varDupLayer)
			(gimp-edit-clear varDupLayer)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(gimp-layer-set-name varDupLayer "layer4 (tmp)")
		);; END layer4 (tmp)
		
		
		;;	add layer4 (tmp) copy
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer4 (tmp)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer4 (tmp)")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-image-merge-down img varDupLayer CLIP-TO-BOTTOM-LAYER)
		)
		(gimp-layer-set-name (car (gimp-image-get-layer-by-name img "layer4 (tmp)")) "layer4 (tmp) copy");; END layer4 (tmp) copy	
		
		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer4 (tmp) copy")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer4 (tmp) copy")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-selection-all img)
			(gimp-edit-clear varDupLayer)
			(gimp-context-set-background '(0 0 0))
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "fading effect 2")))
			(gimp-edit-fill varDupLayer BACKGROUND-FILL)
			(gimp-selection-none img)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer4 (tmp) copy")))
			(gimp-edit-clear varDupLayer)
			(gimp-edit-clear varDupLayer)
			(gimp-edit-clear varDupLayer)
			(gimp-edit-clear varDupLayer)
			(gimp-layer-set-name varDupLayer "layer4 (tmp)")
		);; END add layer4 (tmp)
		
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer4 (tmp) copy")) FALSE)
		
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer4 (tmp) copy")))
		(gimp-context-set-background '(255 255 255))
		(gimp-edit-fill (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "object")))) BACKGROUND-FILL)
		(gimp-edit-fill (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "object")))) BACKGROUND-FILL)
		(gimp-edit-fill (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "object (highPass)")))) BACKGROUND-FILL)
		(gimp-edit-fill (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "object (highPass)")))) BACKGROUND-FILL)
		(gimp-selection-none img)	
		
		; (gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer4 (tmp)")))
		
		;;	add object bottom fade
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object (highPass)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer4 (tmp)")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 6)
			; add copy masks from "object" layer
			(gimp-edit-copy (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "object")))))
			(set! layer-mask (car (gimp-layer-create-mask varDupLayer ADD-WHITE-MASK)))
			(gimp-image-add-layer-mask img varDupLayer layer-mask)
			(set! floating-selection (car (gimp-edit-paste layer-mask 0)))
			(gimp-floating-sel-anchor floating-selection)

			(plug-in-gauss RUN-NONINTERACTIVE img varDupLayer (* ImageHeight 0.04) (* ImageHeight 0.04) 1)
			(gimp-layer-set-name varDupLayer "object bottom fade")
		);; END add object bottom fade

		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer4 (tmp)")) FALSE)


		;;	add "light rays (1)"
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object bottom fade")))
		(let* (
				(base-x 0)
				(base-y 0)
				(base-layer (get-base-layer new-layer-marker))
				(base-width (car (gimp-image-width  img)))
				(base-height (car (gimp-image-height img)))
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "fading effect 1")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(set! base-x (car  (gimp-drawable-offsets base-layer)))
			(set! base-y (cadr (gimp-drawable-offsets base-layer)))
			(set! base-width  (car (gimp-drawable-width  base-layer)))
			(set! base-height (car (gimp-drawable-height base-layer)))
			(gimp-layer-set-opacity varDupLayer 100)
			(gimp-selection-all img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "fading effect 1")))
			(gimp-selection-grow img 25)
			(gimp-context-set-background '(255 255 255))
			(gimp-edit-fill varDupLayer BACKGROUND-FILL)
			(gimp-selection-shrink img 45)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(plug-in-gauss RUN-NONINTERACTIVE img varDupLayer 12 12 1)
			;; TIME !!!!
			(plug-in-mblur RUN-NONINTERACTIVE img varDupLayer 2 (+ 70 (rand 20)) 0 (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)))
			(plug-in-mblur RUN-NONINTERACTIVE img varDupLayer 2 (+ 50 (rand 10)) 0 (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)))
			
			; add masks
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer3 (tmp) copy")))
			(gimp-selection-invert img)
			(set! layer-mask (car (gimp-layer-create-mask varDupLayer ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img varDupLayer layer-mask)
			(gimp-selection-none img)
			; fill black mask
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer3 (tmp) copy")))
			(gimp-context-set-background '(0 0 0))
			(gimp-edit-fill (car (gimp-layer-get-mask varDupLayer)) BACKGROUND-FILL)
			(gimp-selection-none img)
			(gimp-layer-set-opacity varDupLayer 80)
			(gimp-layer-set-name varDupLayer "light rays (1)")
		);; END add "light rays (1)"

		;;	add "light rays (2)"
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "light rays (1)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "light rays (1)")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)			
			(gimp-layer-set-name varDupLayer "light rays (2)")
		);; END "light rays (2)"

		(gimp-layer-scale-full (car (gimp-image-get-layer-by-name img "light rays (1)")) (* ImageWidth 1.12) (* ImageHeight 1.12) TRUE INTERPOLATION-CUBIC)


		;;	bg light (right)
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Brightness/Contrast 001")))
		(let* (
				(base-x 0)
				(base-y 0)
				(base-layer (get-base-layer new-layer-marker))
				(base-width (car (gimp-image-width  img)))
				(base-height (car (gimp-image-height img)))
				(varDupLayer (car (gimp-layer-copy bg-layer 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-context-set-foreground '(255 255 255))
			(gimp-context-set-background '(0 0 0))
			(set! base-x (car  (gimp-drawable-offsets base-layer)))
			(set! base-y (cadr (gimp-drawable-offsets base-layer)))
			(set! base-width  (car (gimp-drawable-width  base-layer)))
			(set! base-height (car (gimp-drawable-height base-layer)))
			(python-layer-fx-gradient-overlay RUN-NONINTERACTIVE img varDupLayer "Rays small- 3d-hobby-art.de" GRADIENT-LINEAR REPEAT-NONE FALSE 36 SCREEN-MODE (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)) 50 (* (car (gimp-drawable-width brush-layer)) 1.6) FALSE)
			(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "background copy-gradient" (if (= inLanguage 1) "background-Kopie-gradient")) )) 0 12)
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "background copy-with-gradient" (if (= inLanguage 1) "background-Kopie-with-gradient")) )))
			(gimp-layer-set-name (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "background copy-gradient" (if (= inLanguage 1) "background-Kopie-gradient")) )) "bg light (right)")
		);; END bg light (right)
		
		;;	bg light (left)
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "bg light (right)")))
		(let* (
				(base-x 0)
				(base-y 0)
				(base-layer (get-base-layer new-layer-marker))
				(base-width (car (gimp-image-width  img)))
				(base-height (car (gimp-image-height img)))
				(varDupLayer (car (gimp-layer-copy bg-layer 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-context-set-foreground '(255 255 255))
			(gimp-context-set-background '(0 0 0))
			(set! base-x (car  (gimp-drawable-offsets base-layer)))
			(set! base-y (cadr (gimp-drawable-offsets base-layer)))
			(set! base-width  (car (gimp-drawable-width  base-layer)))
			(set! base-height (car (gimp-drawable-height base-layer)))
			(python-layer-fx-gradient-overlay RUN-NONINTERACTIVE img varDupLayer "Rays small- 3d-hobby-art.de" GRADIENT-LINEAR REPEAT-NONE FALSE 40 SCREEN-MODE (- (+ base-x (/ base-width  2)) (/ 100  2)) (- (+ base-y (/ base-height 2)) (/ 100 2)) -45 (* (car (gimp-drawable-width brush-layer)) 1.8) FALSE)
			(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "background copy-gradient" (if (= inLanguage 1) "background-Kopie-gradient")) )) 0 12)
			(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "background copy-with-gradient" (if (= inLanguage 1) "background-Kopie-with-gradient")))))
			(gimp-layer-set-name (car (gimp-image-get-layer-by-name img (if (= inLanguage 0) "background copy-gradient" (if (= inLanguage 1) "background-Kopie-gradient")) )) "bg light (left)")
		);; END bg light (left)

		;;	add masks from "bg light (wide)" layer to "bg light (right)" layer
		;; ************************************************************************************************************************************
		(gimp-edit-copy (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "bg light (wide)")))))
		(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "bg light (right)")) ADD-WHITE-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "bg light (right)")) layer-mask)
		(set! floating-selection (car (gimp-edit-paste layer-mask 0)))
		(gimp-floating-sel-anchor floating-selection) ;; END add masks from "bg light (wide)" layer to "bg light (right)" layer

		;;	add masks from "bg light (wide)" layer to "bg light (left)" layer
		;; ************************************************************************************************************************************
		(gimp-edit-copy (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "bg light (wide)")))))
		(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "bg light (left)")) ADD-WHITE-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "bg light (left)")) layer-mask)
		(set! floating-selection (car (gimp-edit-paste layer-mask 0)))
		(gimp-floating-sel-anchor floating-selection) ;; END add masks from "bg light (wide)" layer to "bg light (left)" layer
		
		
		;;	add "object #contrast"
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "object")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "object")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-gauss RUN-NONINTERACTIVE img varDupLayer (* ImageHeight 0.02) (* ImageHeight 0.02) 1)
			(gimp-layer-set-mode varDupLayer SOFTLIGHT-MODE)
			(gimp-layer-set-name varDupLayer "object #contrast")
		);; END add "object #contrast"

		
		;;	add layer11
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "light rays (2)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer1")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-selection-all img)
			(gimp-context-set-background '(0 0 0))
			(gimp-edit-fill varDupLayer BACKGROUND-FILL)
			(gimp-selection-none img)
			(plug-in-hsv-noise RUN-NONINTERACTIVE img varDupLayer 8 180 255 255)
			(gimp-desaturate-full varDupLayer DESATURATE-LIGHTNESS)
			(gimp-layer-set-name varDupLayer "layer11")
		);; END add layer11

		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "light rays (2)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer1")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-selection-all img)
			(gimp-context-set-background '(0 0 0))
			(gimp-edit-fill varDupLayer BACKGROUND-FILL)
			(gimp-selection-none img)
			(plug-in-plasma RUN-NONINTERACTIVE img varDupLayer seed 3)
			(gimp-desaturate-full varDupLayer DESATURATE-LIGHTNESS)
			(gimp-invert varDupLayer)
			(gimp-layer-set-name varDupLayer "layer11 mask")
		);; END add layer11 mask
		
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer11 mask")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer1")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-selection-all img)
			(gimp-context-set-background '(0 0 0))
			(gimp-edit-fill varDupLayer BACKGROUND-FILL)
			(gimp-selection-none img)
			(plug-in-plasma RUN-NONINTERACTIVE img varDupLayer seed 2)
			(gimp-desaturate-full varDupLayer DESATURATE-LIGHTNESS)
			(gimp-invert varDupLayer)
			(gimp-item-set-visible varDupLayer FALSE)
			(gimp-layer-set-name varDupLayer "layer11 mask (2)")
		);; END add layer11 mask (2)


		;;	add small Particles (add dots)
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "light rays (2)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer11")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-levels varDupLayer HISTOGRAM-VALUE 120 255 2 0 255)
			(gimp-by-color-select-full varDupLayer '(150 150 150) (+ 4 (rand 4)) CHANNEL-OP-ADD FALSE FALSE 1 1 TRUE FALSE SELECT-CRITERION-COMPOSITE)
			(gimp-selection-grow img 2)
			(gimp-context-set-background '(255 255 255))
			(gimp-edit-fill varDupLayer BACKGROUND-FILL)
			(gimp-selection-invert img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(plug-in-gauss RUN-NONINTERACTIVE img varDupLayer 1 1 1)
			(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer11")) FALSE)
			(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "layer11 mask")) FALSE)
			(gimp-layer-set-name varDupLayer "small Particles")
			(python-layer-fx-outer-glow RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "small Particles")) '(255 255 255) 75 0 0 NORMAL-MODE 0 6 FALSE FALSE)
		
			;;	add copy masks from "bg light (wide)" layer
			;; ************************************************************************************************************************************
			(gimp-edit-copy (car (gimp-image-get-layer-by-name img "layer11 mask")))
			(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "small Particles")) ADD-WHITE-MASK)))
			(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "small Particles")) layer-mask)
			(set! floating-selection (car (gimp-edit-paste layer-mask 0)))
			(gimp-floating-sel-anchor floating-selection) ;; END add copy masks from "object" layer
			
			(gimp-edit-copy (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "small Particles")))))
			(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "small Particles-outerglow")) ADD-WHITE-MASK)))
			(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "small Particles-outerglow")) layer-mask)
			(set! floating-selection (car (gimp-edit-paste layer-mask 0)))
			(gimp-floating-sel-anchor floating-selection) ;; END add copy masks from "small Particles" layer
			
			(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "small Particles-with-outerglow")) 80)
			(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "small Particles-with-outerglow")) OVERLAY-MODE)
			
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer3 (tmp)")))
			(gimp-context-set-background '(0 0 0))
			(gimp-edit-fill (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "small Particles")))) BACKGROUND-FILL)
			(gimp-edit-fill (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "small Particles-outerglow")))) BACKGROUND-FILL)
			(gimp-selection-none img)
		);; END add small Particles (add dots)


		;;	add "soft contrast (1)" layer
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "layer11 mask")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer1")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer4 (tmp) copy")))
			(gimp-selection-invert img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(gimp-selection-feather img 25)
			(gimp-selection-layer-alpha varDupLayer)
			(gimp-selection-shrink img 40)
			(gimp-edit-clear varDupLayer)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(gimp-layer-set-mode varDupLayer DODGE-MODE)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer3 (tmp) copy")))
			(gimp-selection-invert img)
			(set! layer-mask (car (gimp-layer-create-mask varDupLayer ADD-SELECTION-MASK)))
			(gimp-image-add-layer-mask img varDupLayer layer-mask)
			(gimp-selection-none img)
			(gimp-layer-set-name varDupLayer "soft contrast (1)")
		);; END add "soft contrast (1)" layer
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "layer11 mask")))
		
		;; add "soft contrast (2)" layer
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "soft contrast (1)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "soft contrast (1)")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-opacity varDupLayer 70)
			(gimp-layer-set-name varDupLayer "soft contrast (2)")
		);; END add "soft contrast (2)" layer


		;;	add big Particles (add dots)
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "light rays (2)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer11")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-item-set-visible varDupLayer TRUE)
			(gimp-levels varDupLayer HISTOGRAM-VALUE 130 255 2 0 255)
			(gimp-by-color-select-full varDupLayer '(155 155 155) (+ 4 (rand 4)) CHANNEL-OP-ADD FALSE FALSE 1 1 TRUE FALSE SELECT-CRITERION-COMPOSITE)
			(gimp-selection-grow img 2)
			(gimp-context-set-background '(255 255 255))
			(gimp-edit-fill varDupLayer BACKGROUND-FILL)
			(gimp-selection-invert img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(plug-in-gauss RUN-NONINTERACTIVE img varDupLayer 2 2 1)
			
			(gimp-layer-set-name varDupLayer "big Particles")
			(python-layer-fx-outer-glow RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "big Particles")) '(255 255 255) 75 0 0 NORMAL-MODE 0 8 FALSE FALSE)
		
			;;	add copy masks from "bg light (wide)" layer
			;; ************************************************************************************************************************************
			(gimp-edit-copy (car (gimp-image-get-layer-by-name img "layer11 mask (2)")))
			(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "big Particles")) ADD-WHITE-MASK)))
			(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "big Particles")) layer-mask)
			(set! floating-selection (car (gimp-edit-paste layer-mask 0)))
			(gimp-floating-sel-anchor floating-selection) ;; END add copy masks from "object" layer
			
			(gimp-edit-copy (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "big Particles")))))
			(set! layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "big Particles-outerglow")) ADD-WHITE-MASK)))
			(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "big Particles-outerglow")) layer-mask)
			(set! floating-selection (car (gimp-edit-paste layer-mask 0)))
			(gimp-floating-sel-anchor floating-selection) ;; END add copy masks from "big Particles" layer
			
			(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "big Particles-with-outerglow")) 90)
			(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "big Particles-with-outerglow")) NORMAL-MODE)
			
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer3 (tmp)")))
			(gimp-context-set-background '(0 0 0))
			(gimp-edit-fill (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "big Particles")))) BACKGROUND-FILL)
			(gimp-edit-fill (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "big Particles-outerglow")))) BACKGROUND-FILL)
			(gimp-selection-none img)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "layer4 (tmp)")))
			(gimp-context-set-background '(0 0 0))
			(gimp-edit-fill (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "big Particles")))) BACKGROUND-FILL)
			(gimp-edit-fill (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "big Particles-outerglow")))) BACKGROUND-FILL)
			(gimp-selection-none img)
		);; END add big Particles (add dots)
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "layer11 mask (2)")))
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "layer11")))
		(gimp-image-reorder-item img (car (gimp-image-get-layer-by-name img "small Particles-with-outerglow")) 0 15)
		

		;;	object contour
		;; ************************************************************************************************************************************
		(gimp-selection-feather img 15)
		(gimp-selection-layer-alpha brush-layer)
		(gimp-selection-shrink img 2)
		(gimp-selection-invert img)
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "object")))
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "soft contrast (1)")))
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "object (highPass)")))
		(gimp-selection-none img);;	END object contour


		;; add "Lens Flare" layer
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "soft contrast (2)")))
		(let* (
				(base-x 0)
				(base-y 0)
				(base-layer (get-base-layer new-layer-marker))
				(base-width (car (gimp-image-width  img)))
				(base-height (car (gimp-image-height img)))
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer1")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-context-set-background '(0 0 0))
			(gimp-edit-fill varDupLayer BACKGROUND-FILL)
			(set! base-x (car  (gimp-drawable-offsets base-layer)))
			(set! base-y (cadr (gimp-drawable-offsets base-layer)))
			(set! base-width  (car (gimp-drawable-width  base-layer)))
			(set! base-height (car (gimp-drawable-height base-layer)))
			(plug-in-flarefx (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer (- (- (+ base-x (/ base-width  2)) (/ 100  2)) (/ (car (gimp-drawable-width brush-layer)) 2.6(rand 5) )) (- (- (+ base-y (/ base-height 2)) (/ 100 2)) (/ (car (gimp-drawable-height brush-layer)) 2.5)) )
			(gimp-layer-set-mode varDupLayer SCREEN-MODE)
			(gimp-layer-set-opacity varDupLayer 55)
			(gimp-layer-set-name varDupLayer "lens flare")
		);; END add "Lens Flare" layer

		
		
		;;	final
		;; ************************************************************************************************************************************
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "object (highPass)")) FALSE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "object")) FALSE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "object #contrast")) FALSE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "soft contrast (1)")) FALSE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "soft contrast (2)")) FALSE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "lens flare")) FALSE)

		;;	add object invert for mask (Hue/Saturation layer)
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "light rays (1)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-layer-by-name img "layer1")) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-invert varDupLayer)
			(gimp-item-set-visible varDupLayer FALSE)
			(gimp-layer-set-name varDupLayer "object invert")
		);; END add object invert for mask (Hue/Saturation layer)
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "layer1")))

		;;	Hue/Saturation layer
		;; ************************************************************************************************************************************
		(gimp-edit-copy-visible img)
		(gimp-image-insert-layer img hue-saturation-layer 0 0)
		(set! floating-selection (car (gimp-edit-paste hue-saturation-layer 0)))
		(gimp-floating-sel-anchor floating-selection)
		(gimp-colorize (car (gimp-image-get-layer-by-name img "Hue/Saturation")) 225 30 -5)
		(set! hue-saturation-layer-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "Hue/Saturation")) ADD-WHITE-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "Hue/Saturation")) hue-saturation-layer-mask)
		(gimp-edit-copy (car (gimp-image-get-layer-by-name img "object invert")))
		(set! floating-selection (car (gimp-edit-paste hue-saturation-layer-mask 0)))
		(gimp-floating-sel-anchor floating-selection)
		(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "Hue/Saturation")) 74)
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "object invert"))) 	;; END Hue/Saturation layer
		
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "object (highPass)")) TRUE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "object")) TRUE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "object #contrast")) TRUE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "soft contrast (1)")) TRUE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "soft contrast (2)")) TRUE)
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "lens flare")) TRUE)
		;; ************************************************************************************************************************************

		
		;;	Brightness/Contrast 002
		;; ************************************************************************************************************************************
		(gimp-edit-copy-visible img)
		(set! brightness-contrast-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "Brightness/Contrast 002" 100 NORMAL)))
		(gimp-image-insert-layer img brightness-contrast-layer 0 0)		
		(set! floating-selection (car (gimp-edit-paste brightness-contrast-layer 0)))
		(gimp-floating-sel-anchor floating-selection)
		(gimp-brightness-contrast (car (gimp-image-get-layer-by-name img "Brightness/Contrast 002")) -100 18)
		(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "Brightness/Contrast 002")) 50)
		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "Brightness/Contrast 002")) OVERLAY-MODE) ;; END Brightness/Contrast 002


		;;	Exposure (Softlight)
		;; ************************************************************************************************************************************
		(gimp-edit-copy-visible img)
		(set! softlight-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "Exposure (Softlight)" 100 NORMAL)))
		(gimp-image-insert-layer img softlight-layer 0 0)		
		(set! floating-selection (car (gimp-edit-paste softlight-layer 0)))
		(gimp-floating-sel-anchor floating-selection)
		(plug-in-colortoalpha RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "Exposure (Softlight)")) '(0 0 0))
		(plug-in-gauss RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "Exposure (Softlight)")) 12 12 1)
		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "Exposure (Softlight)")) SOFTLIGHT-MODE) ;; END Exposure (Softlight)


		;; delete/hide layers
		(gimp-image-remove-layer img new-layer-marker)
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "layer2 (tmp)")))
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "layer3 (tmp) copy")))
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "layer3 (tmp)")))
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "fading-mask copy")))
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "layer4 (tmp)")))
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "layer4 (tmp) copy")))
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "fading effect 3")))
		
		(gimp-item-set-visible bg-layer FALSE)
		(gimp-item-set-visible brush-layer FALSE)
		
		;; optimize layers
		(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "big Particles-outerglow")))
		(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "light rays (1)")))
		(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "small Particles-outerglow")))
		(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "fading-mask")))
		(gimp-layer-resize-to-image-size (car (gimp-image-get-layer-by-name img "fading effect 2")))


		
		(gimp-palette-set-background old-bg)
		(gimp-palette-set-foreground old-fg)
		
		(if (= inUndoMode TRUE) (begin (gimp-image-undo-group-end img)) )
		(if (= inUndoMode FALSE) (begin (gimp-image-undo-enable img)) )
		
		(gimp-displays-flush)
	) ;; END main let*
)