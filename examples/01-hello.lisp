#-quicklisp
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                       (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))

(ql:quickload :cl-ppcre)
(asdf:load-system :cl-ffmpeg)

(cl-ffmpeg:with-ffmpeg ()
  (cl-ffmpeg:run-ffmpeg (cl-ffmpeg-inherit:audio-params) ;; <- the ffmpeg-env struct
              (pathname "/home/tassos/Videos/test.mp4")
              (pathname "/home/tassos/Videos/dummy.wav")))
