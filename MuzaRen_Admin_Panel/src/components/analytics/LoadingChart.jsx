// Skeleton loader for charts while data is loading
export default function LoadingChart({ height = 300 }) {
  return (
    <div
      className="animate-pulse bg-gray-100 rounded-lg w-full"
      style={{ height }}
    />
  );
}
