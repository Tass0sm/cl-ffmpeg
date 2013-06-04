(in-package :cl-ffmpeg)

(define-foreign-library libavformat
  (:unix (:or "/usr/local/lib/libavformat.so"))
  (t (:default "libavformat")))

(use-foreign-library libavformat)

(define-foreign-library libavcodec
  (:unix (:or "/usr/local/lib/libavcodec.so"))
  (t (:default "libavcodec")))

(use-foreign-library libavcodec)

(define-foreign-library ffmpeg-wrapper
  (:unix (:or "/usr/local/lib/ffmpeg-wrapper.so"))
  (t (:default "ffmpeg-wrapper")))

(use-foreign-library ffmpeg-wrapper)

(defparameter *err-buffer-length* 1024)

(defmacro define-dummy-enums(&rest enums)
  `(progn
     ,@(loop for enum in enums collecting
	    `(defcenum ,enum
	       (,(to-keyword (.sym enum '-unknown)) -1)))))

(defmacro defcstruct*(name-and-options &body fields)
  (let ((type (get-first-atom name-and-options)))
    `(progn
       (defcstruct ,name-and-options ,@fields)
       ,@(loop for item in fields collecting 
	      (let ((slot-name (get-first-atom item)))
		`(defmacro ,(.sym (get-first-atom name-and-options) '- (get-first-atom item)) (ptr) 
		   `(foreign-slot-value ,ptr ,'',type ,'',slot-name)))))))

(defcenum AVDuration-Estimation-Method
  :AVFMT-DURATION-FROM-PTS 
  :AVFMT-DURATION-FROM-STREAM
  :AVFMT-DURATION_FROM-BITRATE)

(defcenum AVIO-Codec-ID
  :AVCODEC-ID-NONE)

(defcstruct* AVIO-Interrupt-CB
	(callback :pointer)
	(opaque :pointer))

(defcstruct* AVRational
  (num :int)
  (den :int))
 
(defcenum avmedia-type
  (:avmedia-type-unknown -1)
  :avmedia-type-video
  :avmedia-type-audio)

(defcfun ("av_register_all" av-register-all) :void)

(defcfun ("avformat_open_input" avformat-open-input) :int
  (ps :pointer)
  (filename :string)
  (fmt :pointer)
  (options :pointer))

(defcfun ("avformat_find_stream_info" avformat-find-stream-info) :int
  (ic :pointer)
  (options :pointer))

(defctype size-t :uint)

(defcfun ("av_strerror" av-strerror) :int
  (errnum :int)
  (errbuf :string)
  (errbuf-size size-t))

(define-condition ffmpeg-fault(error)
  ((msg :initarg :msg :reader msg)
   (code :initform nil :initarg :code :reader code))
  (:report (lambda(c stream)(if (code c) 
				(with-foreign-object  (buffer :char *err-buffer-length*)
				  (av-strerror (code c) buffer *err-buffer-length*)
				  (format stream "ffmpeg lib:~a error-code:~a:~a" (msg c) (code c) (foreign-string-to-lisp buffer)))
				  (format stream "ffmpeg lib:~a" (msg c))))))			
  
(defcfun ("av_find_best_stream" av-find-best-stream) :int
  (ic :pointer)
  (type avmedia-type)
  (wanted_stream_nb :int)
  (related_stream :int)
  (decoder_ret :pointer)
  (flags :int))

(defcfun ("avcodec_alloc_context3" avcodec-alloc-context3) :pointer
  (codec :pointer))

(defcfun ("av_freep" avfreep) :void
  (ptr :pointer))

(defcfun ("avcodec_open2" avcodec-open2) :int
  (avctx :pointer)
  (codec :pointer)
  (options :pointer))

(defcfun ("avcodec_close" avcodec-close) :int
  (avctx :pointer))

(defcfun ("avformat_close_input" avformat-close-input) :void 
  (ss :pointer))
	
(defcfun ("av_frame_alloc" av-frame-alloc) :pointer)
(defcfun ("av_frame_free" av-frame-free) :void 
  (p-frame :pointer))

(defcenum AVPacket-Side-Data-Types
  (:unknown 0))

(defcstruct* AVPacket-Side-Data
  (data :pointer)
  (size :int)
  (type AVPacket-Side-Data-Types))

(defcstruct* AVPacket
  (buf :pointer)
  (pts :int64)
  (dts :int64)
  (data :pointer)
  (size :int)
  (stream-index :int)
  (flags :int)
  (side-data AvPacket-Side-Data)
  (side-data-elems :int)
  (duration :int)
  (pos :int64)
  (convergence-duration :int64))

(defcfun ("av_read_frame" av-read-frame) :int
    (format-context :pointer)
    (packet :pointer))

(defcfun ("av_init_packet" av-init-packet) :void
  (packet :pointer))

(defcfun ("av_free_packet" av-free-packet) :void
  (packet :pointer))

(defcfun ("avcodec_decode_audio4" avcodec-decode-audio4) :int
  (codec-context :pointer)
  (frame :pointer)
  (got-frame-ptr :pointer)
  (avpk :pointer))

(defcfun ("avcodec_decode_video2" avcodec-decode-video2) :int
  (codec-context :pointer)
  (picture :pointer)
  (got-frame-ptr :pointer)
  (avpk :pointer))

(defcenum AVSample-Format 
   (:AV-SAMPLE-FMT-NONE -1)
   :AV-SAMPLE-FMT-U8
   :AV-SAMPLE-FMT-S16
   :AV-SAMPLE-FMT-S32
   :AV-SAMPLE-FMT-FLT
   :AV-SAMPLE-FMT-DBL 
   :AV-SAMPLE-FMT-U8P
   :AV-SAMPLE-FMT-S16P
   :AV-SAMPLE-FMT-S32P
   :AV-SAMPLE-FMT-FLTP
   :AV-SAMPLE-FMT-DBLP 
   :AV-SAMPLE-FMT-NB)

(defcfun ("avcodec_find_encoder_by_name" avcodec-find-encoder-by-name) :pointer
  (name  :string))	

(define-dummy-enums AVCodec-ID AVPixel-Format AVColor-Primaries AVColor-Transfer-Characteristic AVColor-Space AVColor-Range AVChroma-Location AVField-Order AVAudio-Service-Type) 
         
(defcfun ("av_get_channel_layout" av-get-channel-layout) :uint64	
  (name :string))

(defcfun ("av_get_channel_layout_nb_channels" av-get-channel-layout-nb-channels) :int
    (channel_layout :uint64))	

(defcfun ("av_get_default_channel_layout" av-get-default-channel-layout) :int64
  (nb-channels :int))

(defcfun ("my_test" my-test) :int
    (msg :string))

(defmacro define-ffmpeg-wrappers(prefix &body name-types)
  `(progn
     ,@(with-collector 
	(!push)
	(loop for (name type) in name-types do
	     (unless type (error 'ffmpeg-fault :msg (% "No type for ~a-~a" prefix name)))  
	     (let ((accessor-name (.sym prefix '- name))(lisp-get-name (.sym prefix '-get- name))(lisp-set-name (.sym prefix '-set- name)))
	       (flet ((lisp-to-c(lisp-name)
			(string-downcase (cl-ppcre:regex-replace-all "\\-" (symbol-name lisp-name) "_"))))
		 (let ((c-get-name (lisp-to-c lisp-get-name))(c-set-name (lisp-to-c lisp-set-name)))
		   (!push `(defcfun (,c-get-name ,accessor-name) ,type
			     (,prefix :pointer)))
		   (!push `(defcfun (,c-set-name ,lisp-set-name) :void
			     (,prefix :pointer)
			     (,name ,type)))
		   (!push `(defsetf ,accessor-name ,lisp-set-name)))))))))

(define-ffmpeg-wrappers codec-context
  (channel-layout :uint64)
  (channels :int)
  (sample-fmt AVSample-Format)
  (sample-rate :int)
  (bit-rate :int))

(defparameter *decoders* ({} (:avmedia-type-audio (foreign-symbol-pointer "avcodec_decode_audio4"))(:avmedia-type-video (foreign-symbol-pointer "avcodec_decode_video2"))))

(defparameter *encoders* ({} (:avmedia-type-audio (foreign-symbol-pointer "avcodec_encode_audio2"))(:avmedia-type-video (foreign-symbol-pointer "avcodec_encode_video2"))))

(defmacro with-av-pointer(ptr allocator &body body)
  (with-gensyms (holder)
    `(let ((,ptr ,allocator))
       (unless (null-pointer-p ,ptr)
	 (unwind-protect
	      (progn
		,@body)
	   (with-foreign-object (,holder :pointer)
	     (setf (mem-ref ,holder :pointer) ,ptr)
	     (avfreep ,holder)))))))

(defmacro with-av-frame(av-frame &body body)
  (with-gensyms (holder)
    `(let ((,av-frame (av-frame-alloc)))
       (unwind-protect
	    (progn
	      ,@body)
	 (with-foreign-object (,holder :pointer)
	   (setf (mem-ref ,holder :pointer) ,av-frame)
	   (av-frame-free ,holder))))))

(defmacro with-av-frames((&rest av-frames) &body body)
  (with-gensyms (holder)
    `(let 
	 ,(loop for av-frame in av-frames collecting
	       `(,av-frame (av-frame-alloc)))
       (unwind-protect
	    (progn
	      ,@body)
	 ,@(loop for av-frame in av-frames collecting
	       `(with-foreign-object (,holder :pointer)
		  (setf (mem-ref ,holder :pointer) ,av-frame)
		  (av-frame-free ,holder)))))))

(defmacro with-av-packet(av-packet &body body)
  `(with-foreign-object(,av-packet 'AVPacket)
     (av-init-packet ,av-packet)
     (unwind-protect
	  (progn
	    ,@body)
       (av-free-packet ,av-packet))))

(defmacro in-frame-read-loop(format-context stream-idx packet &body body)
  `(loop
      (with-av-packet ,packet
	(unless (= (av-read-frame ,format-context ,packet) 0) 
	  (return))
	(if (= ,stream-idx (AVPacket-stream-index ,packet))
	    (progn
	      (format t "stream-idx:~a:~a~%" ,stream-idx (AVPacket-stream-index ,packet))
	      ,@body)))))

(defmacro with-decoded-frame((codec-context stream-type frame packet) &body body)
  (with-gensyms (p-got-frame-ptr ret packet-size)
    `(with-foreign-object (,p-got-frame-ptr :int) 
       (let ((,packet-size (AVPacket-size ,packet)))
	 (let ((,ret (foreign-funcall-pointer ([] *decoders* ,stream-type) () :pointer ,codec-context :pointer ,frame :pointer ,p-got-frame-ptr :pointer ,packet :int)))
	   (unless (= ,ret ,packet-size) (error 'ffmpeg-fault :msg (% "decode fault -> decoded bytes:~a expected bytes~a" ,ret ,packet-size)))
	   (unless (= (mem-ref ,p-got-frame-ptr :int) 0)
	     ,@body))))))

(defmacro with-open-input((p-format-context file-path ) &body body)
  (with-gensyms (pp-format-context c-file-path ret)
    `(with-foreign-string (,c-file-path ,file-path)
       (with-foreign-objects ((,pp-format-context :pointer))
	 (setf (mem-ref ,pp-format-context :pointer) (null-pointer))
	 (let ((,ret (avformat-open-input ,pp-format-context ,c-file-path (null-pointer) (null-pointer))))
	   (unless (= ,ret 0) (error 'ffmpeg-fault :msg (% "unable to open:~a" ,file-path) :code ,ret))
	   (let ((,p-format-context (mem-ref ,pp-format-context :pointer)))
	     (if (not (null-pointer-p ,p-format-context))
		 (progn
		   (unwind-protect
			(progn
			  ,@body)
		     (avformat-close-input ,pp-format-context))))))))))

(defmacro with-open-codec((codec-context codec &optional name) &body body)
  (with-gensyms (ret)
    `(let ((,ret (avcodec-open2 ,codec-context ,codec (null-pointer))))
       (unless (= ,ret 0) (error 'ffmpeg-fault :msg (% "codec open fault:~a" (or ,name "unknown")) :code ,ret))
       (unwind-protect
	    (progn
	      ,@body)
	 (avcodec-close ,codec-context)))))

(defun open-codec-2(codec-context codec &optional name)
  (let ((ret (avcodec-open2 codec-context codec (null-pointer))))
       (unless (= ret 0) (error 'ffmpeg-fault :msg (% "codec open fault:~a" (or name "unknown")) :code ret))))
       		 
(defmacro with-input-stream((p-format-context p-codec-context stream-idx file-path media-type) &body body)
  (with-gensyms (pp-codec p-codec)
    `(with-open-input (,p-format-context ,file-path)
       (avformat-find-stream-info ,p-format-context (null-pointer))
       (with-foreign-object (,pp-codec :pointer)
	 (let ((,stream-idx (av-find-best-stream ,p-format-context (foreign-enum-value 'avmedia-type ,media-type) -1 -1 ,pp-codec 0)))
	   (let ((,p-codec-context (get-codec-context ,p-format-context ,stream-idx))(,p-codec (mem-ref ,pp-codec :pointer)))
	     (open-codec-2 ,p-codec-context ,p-codec)
	     ,@body))))))

(defcstruct* (AVFormat-Context-Overlay)
  (av-class  :pointer)
  (iformat  :pointer)
  (oformat  :pointer)
  (priv-data  :pointer)
  (pb  :pointer)
  (ctx-flags  :int)
  (nb-streams  :unsigned-int)
  (streams  :pointer))

(defcstruct* (AVStream-Overlay)
  (index :int)
  (id :int)
  (codec :pointer))

(defun get-codec-context(format-context stream-idx)
  (let ((nb-streams (AVFormat-Context-Overlay-nb-streams format-context)))
    (cond ((>= stream-idx nb-streams)
	   (error 'ffmpeg-fault :msg (% "stream index:~a too high" stream-idx)))
	  ((< stream-idx 0)
	   (error 'ffmpeg-fault :msg (% "stream index below zero"))))
    (let ((streams (AVFormat-Context-Overlay-streams format-context)))
      (let ((stream (mem-aref streams :pointer stream-idx)))
	(AVStream-Overlay-codec stream)))))

(defmacro with-encoder((codec-context codec name) &body body)
  `(let ((,codec (avcodec-find-encoder-by-name ,name)))
     (when (null-pointer-p ,codec) (error 'ffmpeg-fault :msg (% "codec ~a not found" ,name)))
     (with-av-pointer ,codec-context (avcodec-alloc-context3 ,codec)
       (when (null-pointer-p ,codec-context) (error 'ffmpeg-fault :msg (% "failed to open codec context:~a" ,name)))
       (unwind-protect
	    (progn
	      ,@body)
	 (avcodec-close ,codec-context)))))

(defmacro with-audio-encoder!((codec-context name &key (sample-rate 44100) (channel-layout "stereo") bit-rate) &body body)
  (with-gensyms (codec channel-layout-id)
    `(with-encoder (,codec-context ,codec ,name)
       (format t "BEFORE-> channels:~a sample-rate:~a bit-rate:~a: channel-layout:~a~%" (codec-context-channels ,codec-context) (codec-context-sample-rate ,codec-context) (codec-context-bit-rate ,codec-context) (codec-context-channel-layout ,codec-context))
       (let ((,channel-layout-id (av-get-channel-layout ,channel-layout)))
	 (when (= ,channel-layout-id 0) (error 'ffmpeg-fault :msg (% "no channel layout:~a" ,channel-layout)))
	 (setf (codec-context-channel-layout ,codec-context) ,channel-layout-id)
	 (setf (codec-context-channels ,codec-context) (av-get-channel-layout-nb-channels ,channel-layout-id))
	 (setf (codec-context-sample-rate ,codec-context) ,sample-rate)
	 (setf (codec-context-sample-fmt ,codec-context) (foreign-enum-value 'AVSample-Format :AV-SAMPLE-FMT-S16))
	 ;(codec-context-set-sample-fmt ,codec-context :AV-SAMPLE-FMT-S16)
	 (when ,bit-rate (setf (codec-context-bit-rate ,codec-context) ,bit-rate))
	 (format t "AFTER-> channels:~a sample-rate:~a bit-rate:~a: channel-layout:~a~%" (codec-context-channels ,codec-context) (codec-context-sample-rate ,codec-context) (codec-context-bit-rate ,codec-context) (codec-context-channel-layout ,codec-context)))
       (with-open-codec (,codec-context ,codec ,name) 
	 ,@body))))

(defmacro with-audio-encoder((codec-context name &key (sample-rate 44100) (num-channels 2) bit-rate) &body body)
  (with-gensyms (codec)
    `(with-encoder (,codec-context ,codec ,name)
       (format t "BEFORE-> channels:~a sample-rate:~a bit-rate:~a: channel-layout:~a~%" (codec-context-channels ,codec-context) (codec-context-sample-rate ,codec-context) (codec-context-bit-rate ,codec-context) (codec-context-channel-layout ,codec-context))
       (setf (codec-context-channel-layout ,codec-context) (av-get-default-channel-layout ,num-channels))
       (setf (codec-context-channels ,codec-context) ,num-channels)
       (setf (codec-context-sample-rate ,codec-context) ,sample-rate)
       (setf (codec-context-sample-fmt ,codec-context) (foreign-enum-value 'AVSample-Format :AV-SAMPLE-FMT-S16P))
       (when ,bit-rate (setf (codec-context-bit-rate ,codec-context) ,bit-rate))
       (format t "AFTER-> channels:~a sample-rate:~a bit-rate:~a: channel-layout:~a~%" (codec-context-channels ,codec-context) (codec-context-sample-rate ,codec-context) (codec-context-bit-rate ,codec-context) (codec-context-channel-layout ,codec-context))
       (with-open-codec (,codec-context ,codec ,name) 
	 ,@body))))

(defmacro with-encoded-packet((codec-context stream-type packet frame) &body body)
  (with-gensyms (p-got-packet-ptr ret)
    `(with-foreign-object (,p-got-packet-ptr :int)
       (with-av-packet ,packet 
	 (let ((,ret (foreign-funcall-pointer ([] *encoders* ,stream-type) () :pointer ,codec-context :pointer ,packet :pointer ,frame :pointer ,p-got-packet-ptr :int)))
	   (unless (= ,ret 0) (error 'ffmpeg-fault :msg (% "encode fault" :code ,ret)))
	   (unless (= (mem-ref ,p-got-packet-ptr :int) 0)
	     ,@body))))))

(defun test-ffmpeg(&optional (stream-type :avmedia-type-audio))
  (av-register-all)
  (let ((frames 0))
    (with-input-stream (p-format-context-in p-codec-context-in stream-idx "/mnt/MUSIC-THD/test.hd.mp4" stream-type)
      (with-audio-encoder (p-codec-context-out "libmp3lame" :num-channels 2 :bit-rate 64000) 
	(with-av-frame frame
	  (in-frame-read-loop p-format-context-in stream-idx packet-in
	    (with-decoded-frame (p-codec-context-in stream-type frame packet-in)
	      (with-encoded-packet (p-codec-context-out stream-type packet-out frame)
		(incf frames)
		(format t "frame-count:~a~%" frames))))
	    (format t "frames-count:~a decode-context:~a~%" frames p-codec-context-in)))))))

(defun run())


