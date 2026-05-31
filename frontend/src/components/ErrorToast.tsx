import { useEffect, useState } from 'react';

interface ErrorToastProps {
  message: string | null;
  onDismiss: () => void;
}

export function ErrorToast({ message, onDismiss }: ErrorToastProps) {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    if (message) {
      setVisible(true);
      const timer = setTimeout(() => {
        setVisible(false);
        onDismiss();
      }, 6000);
      return () => clearTimeout(timer);
    }
    setVisible(false);
  }, [message, onDismiss]);

  if (!visible || !message) return null;

  return (
    <div className="fixed top-4 right-4 z-50 max-w-sm animate-in slide-in-from-top">
      <div className="bg-red-50 border border-red-200 rounded-lg p-4 shadow-lg flex items-start gap-3">
        <span className="text-red-500 text-lg shrink-0">!</span>
        <div className="flex-1">
          <p className="text-sm text-red-800">{message}</p>
        </div>
        <button
          onClick={() => { setVisible(false); onDismiss(); }}
          className="text-red-400 hover:text-red-600 text-sm shrink-0"
        >
          &times;
        </button>
      </div>
    </div>
  );
}
