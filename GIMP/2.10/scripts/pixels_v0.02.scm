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
;;	v0.02 Pixels!; Gimp v2.10																			;;
;;	(de) http://www.3d-hobby-art.de/news/202-gimp-script-fu-pixels.html									;;
;;	(eng) http://www.3d-hobby-art.de/en/blog/203-gimp-script-fu-pixels.html								;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(script-fu-register
	"script-fu-pixels"														;func name
	"Pixels! (free) ..."															;menu label
	"Pixels! Script turns your photos into a retro Pixel composition."		;desc
	"Stephan W."
	"(c) 2016, 3d-hobby-art.de"							;copyright notice
	"October 03, 2016"														;date created
	"RGBA, RGB"																;image type that the script works on
	SF-IMAGE		"Image"						0
	SF-DRAWABLE		"The layer"					0
	SF-COLOR		_"Add background"			'(8 8 8)
	SF-OPTION		_"Pattern"					'("pixels! Pattern (9x9 pixel)" "pixels! Pattern (11x11 pixel)")		;; pattern
	SF-TOGGLE		"Run Interactive Mode?"		FALSE
	SF-TOGGLE		"Undo Mode?"				FALSE
)
(script-fu-menu-register "script-fu-pixels" "<Image>/Script-Fu/Pixels! Effect")

(define (script-fu-pixels img drawable inBgColor inPattern inRunMode inUndoMode)

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
			(brush-mask-layer (car (gimp-image-get-layer-by-name img "area-brush")))
			(old-bg (car (gimp-context-get-background)))
			(old-fg (car (gimp-context-get-foreground)))
			(ImageWidth  (car (gimp-image-width  img)))
			(ImageHeight (car (gimp-image-height img)))
			(pixel-select-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "pixel select (tmp)" 100 0)))
			(fill-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "background-color" 100 0)))
			(pixel-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "pixels! (tmp)" 100 0)))
			(pixel-group (car (gimp-layer-group-new img)))
			(pixels-layer (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "pixels!" 100 0)))
			(pixels-layer2 (car (gimp-layer-new img ImageWidth ImageHeight RGBA-IMAGE "pixels! #5" 100 0)))
			(lines-wave-glitch-mask)
			(lines-wave-3-mask)
			(lines-wave-2-mask)
			(lines-wave-mask)
			(lines-mask)
			(s-h-mask)
			(lines-blured-2-wave-mask)
			(vector-path)
			(vector-path2)
			(floating-selection)
		)

		;;
		(if  ( = (car (gimp-image-get-layer-by-name img "background")) -1)
			(gimp-message-and-quit "There is no \"background\" layer! Tutorial - please read. \n Keine \"background\" -Ebene gefunden! Bitte lesen Sie mein Tutorial.")
		)
		(if  ( = (car (gimp-image-get-layer-by-name img "area-brush")) -1)
			(gimp-message-and-quit "There is no \"area-brush\" layer! Tutorial - please read. \n Keine \"area-brush\" -Ebene gefunden! Bitte lesen Sie mein Tutorial.")
		)


		;;
		(if (= inUndoMode TRUE) (begin (gimp-image-undo-group-start img)) )
		(gimp-context-push)

		;;
		(gimp-image-lower-item-to-bottom img (car (gimp-image-get-layer-by-name img "area-brush")))
		(gimp-item-set-visible (car (gimp-image-get-layer-by-name img "area-brush")) FALSE)

		;;
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img brush-mask-layer)
		(gimp-image-insert-layer img pixel-select-layer 0 -1)
		(gimp-context-set-feather 50)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "area-brush")))
		(gimp-edit-fill pixel-select-layer WHITE-FILL)
		(gimp-selection-none img)
		(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img pixel-select-layer 80 80 1)
		(gimp-selection-layer-alpha pixel-select-layer)
		(if (= inPattern 0)
			(begin
				(gimp-context-set-pattern "pixels! seamless 9x9")
			)
		)
		(if (= inPattern 1)
			(begin
				(gimp-context-set-pattern "pixels! seamless 11x11")
			)
		)
		(gimp-edit-fill pixel-select-layer PATTERN-FILL)
		(gimp-selection-none img)
		(plug-in-colortoalpha (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img pixel-select-layer '(0 0 0))
		(gimp-item-set-visible pixel-select-layer FALSE)


		;;
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img bg-layer)
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-selection-layer-alpha pixel-select-layer)
			(gimp-selection-invert img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(gimp-layer-set-name varDupLayer "lines blured")
			(gimp-image-remove-layer img pixel-select-layer)
		)

		;;
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "lines blured")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-name varDupLayer "lines")
		)

		;;
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "lines blured")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-name varDupLayer "lines blured 2")
		)

		;;
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "lines blured 2")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-mblur (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 0 (/ ImageWidth 8) 180 (/ ImageWidth 2) (/ ImageHeight 2))
			(gimp-layer-set-name varDupLayer "lines blured 2b")
		)

		(plug-in-mblur (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "lines blured 2")) 0 (/ ImageWidth 8) 0 (/ ImageWidth 2) (/ ImageHeight 2))
		(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "lines blured 2b")) CLIP-TO-BOTTOM-LAYER)
		(gimp-context-set-feather 0)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "lines blured 2")))
		(gimp-selection-invert img)
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "lines blured 2")))
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "lines blured 2")))
		(gimp-selection-none img)

		;;
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "lines blured")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(plug-in-mblur (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 0 (/ ImageWidth (+ (rand 4.5) 1)) 180 (/ ImageWidth 2) (/ ImageHeight 2))
			(gimp-layer-set-name varDupLayer "lines blured 2c")
		)
		(plug-in-mblur (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "lines blured")) 0 (/ ImageWidth (+ (rand 4.5) 1)) 0 (/ ImageWidth 2) (/ ImageHeight 2))
		(gimp-image-merge-down img (car (gimp-image-get-layer-by-name img "lines blured 2c")) CLIP-TO-BOTTOM-LAYER)
		(gimp-context-set-feather 0)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "lines blured")))
		(gimp-selection-invert img)
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "lines blured")))
		(gimp-edit-clear (car (gimp-image-get-layer-by-name img "lines blured")))
		(gimp-selection-none img)
		;;


		(gimp-image-set-active-layer img bg-layer)
		;;
		;; ************************************************************************************************************************************
		(gimp-image-insert-layer img fill-layer 0 -1)
		(gimp-image-set-active-layer img fill-layer)
		(gimp-context-set-foreground inBgColor)
		(gimp-edit-fill fill-layer FOREGROUND-FILL)


		;;
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img bg-layer)
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-desaturate-full varDupLayer DESATURATE-LUMINOSITY)
			(plug-in-gauss (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 4 4 1)
			(gimp-layer-set-name varDupLayer "bg-bump")
		)

		(plug-in-displace (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "lines")) 4 4 1 1 (car (gimp-image-get-layer-by-name img "bg-bump")) (car (gimp-image-get-layer-by-name img "bg-bump")) 1)
		(plug-in-displace (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "lines blured 2")) 4 4 1 1 (car (gimp-image-get-layer-by-name img "bg-bump")) (car (gimp-image-get-layer-by-name img "bg-bump")) 1)
		(plug-in-displace (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "lines blured")) 4 4 1 1 (car (gimp-image-get-layer-by-name img "bg-bump")) (car (gimp-image-get-layer-by-name img "bg-bump")) 1)
		(plug-in-displace (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "lines")) 4 4 1 1 (car (gimp-image-get-layer-by-name img "bg-bump")) (car (gimp-image-get-layer-by-name img "bg-bump")) 1)
		(plug-in-displace (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "lines blured 2")) 4 4 1 1 (car (gimp-image-get-layer-by-name img "bg-bump")) (car (gimp-image-get-layer-by-name img "bg-bump")) 1)
		(plug-in-displace (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "lines blured")) 4 4 1 1 (car (gimp-image-get-layer-by-name img "bg-bump")) (car (gimp-image-get-layer-by-name img "bg-bump")) 1)
		(plug-in-displace (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "lines")) 4 4 1 1 (car (gimp-image-get-layer-by-name img "bg-bump")) (car (gimp-image-get-layer-by-name img "bg-bump")) 1)
		(plug-in-displace (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "lines blured 2")) 4 4 1 1 (car (gimp-image-get-layer-by-name img "bg-bump")) (car (gimp-image-get-layer-by-name img "bg-bump")) 1)
		(plug-in-displace (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "lines blured")) 4 4 1 1 (car (gimp-image-get-layer-by-name img "bg-bump")) (car (gimp-image-get-layer-by-name img "bg-bump")) 1)
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "bg-bump")))
		;;

		;;
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "lines")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-mode varDupLayer DODGE-MODE)
			(gimp-layer-set-name varDupLayer "lines wave")
		)

		;;
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "lines wave")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-mode varDupLayer HARDLIGHT-MODE)
			(gimp-layer-set-name varDupLayer "lines (hard light)")
		)

		(plug-in-waves (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img (car (gimp-image-get-layer-by-name img "lines wave")) 14 0 15 0 TRUE)
		(gimp-image-lower-item img (car (gimp-image-get-layer-by-name img "lines wave")))
		(gimp-image-raise-item img (car (gimp-image-get-layer-by-name img "lines")))

		;;
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "lines blured 2")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-mode varDupLayer DODGE-MODE)
			(plug-in-waves (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 13 0 17 0 TRUE)
			(gimp-layer-set-name varDupLayer "lines blured 2 wave")
		)
		
		;;
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "lines (hard light)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-mode varDupLayer DODGE-MODE)
			(plug-in-waves (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 12 0 16 0 TRUE)
			(gimp-layer-set-name varDupLayer "lines wave 2")
		)

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "lines wave 2")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-flip varDupLayer ORIENTATION-HORIZONTAL)
			(gimp-layer-set-name varDupLayer "lines wave 3")
		)

		;;
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "area-brush")))
		(gimp-selection-invert img)
		(set! lines-blured-2-wave-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "lines blured 2 wave")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "lines blured 2 wave")) lines-blured-2-wave-mask)
		(set! lines-wave-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "lines wave")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "lines wave")) lines-wave-mask)
		(set! lines-wave-2-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "lines wave 2")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "lines wave 2")) lines-wave-2-mask)
		(set! lines-wave-3-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "lines wave 3")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "lines wave 3")) lines-wave-3-mask)
		(gimp-selection-none img)

		;;
		(gimp-image-raise-item img (car (gimp-image-get-layer-by-name img "lines wave")))
		(gimp-image-raise-item img (car (gimp-image-get-layer-by-name img "lines wave")))
		(gimp-image-raise-item img (car (gimp-image-get-layer-by-name img "lines blured 2 wave")))
		(gimp-image-raise-item img (car (gimp-image-get-layer-by-name img "lines blured 2 wave")))
		(gimp-image-raise-item img (car (gimp-image-get-layer-by-name img "lines blured 2 wave")))

		(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "lines")) 80)

		;;
		;;
		(gimp-image-set-active-layer img bg-layer)
		(gimp-image-insert-layer img pixel-layer 0 -1)
		(gimp-context-set-feather 40)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "area-brush")))
		(plug-in-sel2path RUN-NONINTERACTIVE img pixel-layer)
		(gimp-selection-none img)

		;;
		(gimp-context-set-brush "pixsels! Brush")
		(gimp-context-set-brush-size (+ 500 (rand 350)))
		(gimp-context-set-dynamics "Pencil Generic")

		;; 
		;;
		(gimp-context-set-paint-method "gimp-paintbrush")
		(set! vector-path (car (gimp-image-get-active-vectors img)))
		(gimp-edit-stroke-vectors pixel-layer vector-path)
		(gimp-image-remove-vectors img vector-path)

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "lines blured")))
		(gimp-image-insert-layer img pixel-group 0 -1)
		(gimp-item-set-name pixel-group "Pixels!")
		(gimp-layer-set-mode pixel-group DODGE-MODE)
		(gimp-image-insert-layer img pixels-layer pixel-group 0)
		(gimp-context-set-feather (+ 8 (rand 12)))
		(gimp-selection-layer-alpha pixel-layer)
		(gimp-edit-copy (car (gimp-image-get-layer-by-name img "lines blured")))
		(set! floating-selection (car (gimp-edit-paste pixels-layer FALSE)))
		(gimp-floating-sel-anchor floating-selection)

		(gimp-image-set-active-layer img pixels-layer)
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-name varDupLayer "pixels! #2")
		)

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "pixels! #2")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-name varDupLayer "pixels! #3")
		)

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "pixels! #3")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-name varDupLayer "pixels! #4")
		)
		;;

		;;
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img bg-layer)
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-image-raise-item-to-top img varDupLayer)
			(gimp-layer-set-name varDupLayer "Shadow & Highlights")
		)

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Shadow & Highlights")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-desaturate varDupLayer)
			(gimp-invert varDupLayer)
			(gimp-layer-set-mode varDupLayer OVERLAY-MODE)
			(plug-in-gauss-iir2 RUN-NONINTERACTIVE img varDupLayer 25 25)
			(gimp-layer-set-name varDupLayer "fix #Highlights")
		)

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "fix #Highlights")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-name varDupLayer "fix #Shadows")
		)

		(plug-in-colortoalpha RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "fix #Highlights")) '(255 255 255))
		(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "fix #Highlights")) 20)
		(plug-in-colortoalpha RUN-NONINTERACTIVE img (car (gimp-image-get-layer-by-name img "fix #Shadows")) '(0 0 0))
		(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "fix #Shadows")) 80)

		(gimp-selection-all img)
		(gimp-edit-copy-visible img)

		(set! floating-selection (car (gimp-edit-paste (car (gimp-image-get-layer-by-name img "Shadow & Highlights")) FALSE)))
		(gimp-floating-sel-anchor floating-selection)

		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "fix #Shadows")))
		(gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "fix #Highlights")))

		(gimp-layer-set-mode (car (gimp-image-get-layer-by-name img "Shadow & Highlights")) HARDLIGHT-MODE)
		;;

		;;
		;; ************************************************************************************************************************************
		(gimp-image-set-active-layer img pixel-layer)
		(gimp-selection-all img)
		(gimp-edit-clear pixel-layer)

		(gimp-context-set-feather 20)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "area-brush")))
		(plug-in-sel2path RUN-NONINTERACTIVE img pixel-layer)
		(gimp-selection-none img)
		;;
		(gimp-context-set-brush "pixsels! Brush")
		(gimp-context-set-brush-size (+ 900 (rand 550)))
		(gimp-context-set-dynamics "Pencil Generic")

		;;
		;;
		(gimp-context-set-paint-method "gimp-paintbrush")
		(set! vector-path2 (car (gimp-image-get-active-vectors img)))
		(gimp-edit-stroke-vectors pixel-layer vector-path2)
		(gimp-edit-stroke-vectors pixel-layer vector-path2)
		(gimp-image-remove-vectors img vector-path2)


		(gimp-image-insert-layer img pixels-layer2 pixel-group 4)
		(gimp-context-set-feather (+ 10 (rand 8)))
		(gimp-selection-layer-alpha pixel-layer)
		(gimp-edit-copy (car (gimp-image-get-layer-by-name img "lines blured")))
		(set! floating-selection (car (gimp-edit-paste pixels-layer2 FALSE)))
		(gimp-floating-sel-anchor floating-selection)
		(gimp-image-remove-layer img pixel-layer)

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "pixels! #5")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-name varDupLayer "pixels! #6")
		)

		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "pixels! #6")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-flip varDupLayer ORIENTATION-HORIZONTAL)
			(gimp-layer-set-name varDupLayer "pixels! #7")
		)
		;;

		;;
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "pixels!")))
		(let* (
				(varDupLayer (car (gimp-layer-copy bg-layer 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "area-brush")))
			(gimp-selection-invert img)
			(gimp-edit-clear varDupLayer)
			(gimp-selection-none img)
			(plug-in-waves (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 12 360 6 1 FALSE)
			(plug-in-wind (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 10 0 40 1 0)
			(plug-in-wind (if (= inRunMode TRUE) (begin RUN-INTERACTIVE) RUN-NONINTERACTIVE) img varDupLayer 6 1 30 1 0)
			(gimp-layer-set-name varDupLayer "lines glitched")
		)

		(gimp-context-set-feather (+ 3 (rand 6)))
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "lines")))
		(set! lines-wave-glitch-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "lines glitched")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "lines glitched")) lines-wave-glitch-mask)
		(gimp-selection-none img)
		(gimp-levels-stretch (car (gimp-layer-get-mask (car (gimp-image-get-layer-by-name img "lines glitched")))))
		(gimp-image-remove-layer-mask img (car (gimp-image-get-layer-by-name img "lines glitched")) MASK-APPLY)

		;;
		(gimp-layer-set-opacity (car (gimp-image-get-layer-by-name img "Shadow & Highlights")) 60)
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Shadow & Highlights")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-layer-set-mode varDupLayer OVERLAY-MODE)
			(gimp-layer-set-name varDupLayer "Shadow & Highlights (highpass)")
		)
		(gimp-context-set-feather (+ 3 (rand 6)))
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "lines glitched")))
		(set! s-h-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "Shadow & Highlights (highpass)")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "Shadow & Highlights (highpass)")) s-h-mask)
		(gimp-selection-none img)
		;;

		;;
		(gimp-context-set-feather 0)
		(gimp-selection-layer-alpha (car (gimp-image-get-layer-by-name img "area-brush")))
		(set! lines-mask (car (gimp-layer-create-mask (car (gimp-image-get-layer-by-name img "lines")) ADD-SELECTION-MASK)))
		(gimp-image-add-layer-mask img (car (gimp-image-get-layer-by-name img "lines")) lines-mask)
		(gimp-selection-none img)

		;; 
		(gimp-image-set-active-layer img (car (gimp-image-get-layer-by-name img "Shadow & Highlights (highpass)")))
		(let* (
				(varDupLayer (car (gimp-layer-copy (car (gimp-image-get-active-layer img)) 1)))
			)
			(gimp-image-insert-layer img varDupLayer 0 -1)
			(gimp-context-set-foreground '(127 181 60))
			(gimp-edit-fill varDupLayer FOREGROUND-FILL)
			(gimp-layer-set-mode varDupLayer COLOR-MODE)
			(gimp-layer-set-opacity varDupLayer 100)
			(gimp-image-remove-layer-mask img varDupLayer MASK-DISCARD)
			(gimp-layer-set-name varDupLayer "final color")
		)

		(gimp-item-set-visible bg-layer FALSE)

		;;
		(gimp-palette-set-background old-bg)
		(gimp-palette-set-foreground old-fg)
		(gimp-context-pop)
		(if (= inUndoMode TRUE) (begin (gimp-image-undo-group-end img)) )

		(gimp-displays-flush)
	) ;;
)