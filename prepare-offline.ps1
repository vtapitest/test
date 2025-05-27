[V0_FILE]typescriptreact:file="components/personnel-combobox.tsx" isEdit="true" isQuickEdit="true" isMerged="true"
"use client"

import { useState, useRef, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Label } from "@/components/ui/label"
import { Input } from "@/components/ui/input"
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover"
import { ChevronsUpDown, Plus, Check } from "lucide-react"
import { cn } from "@/lib/utils"
import type { PersonnelLists } from "@/lib/types"

interface PersonnelComboboxProps {
  type: keyof PersonnelLists
  value: string
  placeholder: string
  label: string
  options: string[]
  onChange: (value: string) => void
  onAddNew: (type: keyof PersonnelLists, value: string) => Promise<void>
}

export function PersonnelCombobox({
  type,
  value,
  placeholder,
  label,
  options,
  onChange,
  onAddNew,
}: PersonnelComboboxProps) {
  const [open, setOpen] = useState(false)
  const [inputValue, setInputValue] = useState("")
  const [filteredOptions, setFilteredOptions] = useState<string[]>(options)
  const inputRef = useRef<HTMLInputElement>(null)

  // Actualizar las opciones filtradas cuando cambia el input o las opciones
  useEffect(() => {
    if (inputValue) {
      setFilteredOptions(options.filter((option) => option.toLowerCase().includes(inputValue.toLowerCase())))
    } else {
      setFilteredOptions(options)
    }
  }, [inputValue, options])

  // Modificar la función handleAddNew para manejar mejor los errores
  const handleAddNew = async () => {
    if (!inputValue.trim()) return

    try {
      console.log(`Agregando nuevo ${type}:`, inputValue.trim())
      // Llamar a la función para agregar el nuevo valor
      await onAddNew(type, inputValue.trim())

      // Cerrar el popover después de agregar
      setOpen(false)

      // Limpiar el input después de agregar
      setInputValue("")
    } catch (error) {
      console.error(`Error al agregar nuevo ${type}:`, error)
      alert(`Error al agregar nuevo ${type}. Por favor, inténtalo de nuevo.`)
    }
  }

  // Manejar la selección de un valor existente
  const handleSelect = (selected: string) => {
    onChange(selected)
    setOpen(false)
    setInputValue("")
  }

  return (
    <div className="w-full">
      <Label>{label}</Label>
      <Popover open={open} onOpenChange={setOpen}>
        <PopoverTrigger asChild>
          <Button variant="outline" role="combobox" aria-expanded={open} className="w-full justify-between">
            {value || placeholder}
            <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
          </Button>
        </PopoverTrigger>
        <PopoverContent className="w-full p-0" align="start">
          <div className="flex items-center border-b px-3 py-2">
            <Input
              ref={inputRef}
              placeholder={`Buscar o escribir nuevo ${label.toLowerCase()}...`}
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              className="border-0 p-1 shadow-none focus-visible:ring-0"
              onKeyDown={(e) => {
                if (e.key === "Enter") {
                  e.preventDefault()
                  if (inputValue.trim()) {
                    handleAddNew()
                  }
                }
              }}
            />
          </div>
          <div className="max-h-[200px] overflow-y-auto">
            {filteredOptions.length > 0 ? (
              <div className="py-1">
                {filteredOptions.map((option) => (
                  <div
                    key={option}
                    className={cn(
                      "flex cursor-pointer items-center px-3 py-1.5 hover:bg-accent",
                      value === option && "bg-accent",
                    )}
                    onClick={() => handleSelect(option)}
                  >
                    <Check className={cn("mr-2 h-4 w-4", value === option ? "opacity-100" : "opacity-0")} />
                    {option}
                  </div>
                ))}
              </div>
            ) : null}

            {inputValue.trim() && (
              <div className="border-t p-2">
                <Button
                  type="button"
                  variant="ghost"
                  className="w-full justify-start"
                  onClick={(e) => {
                    e.preventDefault()
                    e.stopPropagation()
                    handleAddNew()
                  }}
                >
                  <Plus className="mr-2 h-4 w-4" />
                  Agregar "{inputValue.trim()}"
                </Button>
              </div>
            )}

            {!inputValue.trim() && filteredOptions.length === 0 && (
              <div className="px-3 py-2 text-sm text-muted-foreground">No se encontraron resultados.</div>
            )}
          </div>
        </PopoverContent>
      </Popover>
    </div>
  )
}
[V0_FILE]typescriptreact:file="components/risk-legend.tsx" isMerged="true"
"use client"

import { getRiskBadgeStyles } from "@/lib/utils"
import { Badge } from "@/components/ui/badge"

export function RiskLegend() {
  const riskLevels = [
    { range: "0-12.5%", label: "Minimal", value: 6 },
    { range: "12.5-25%", label: "Very Low", value: 18 },
    { range: "25-37.5%", label: "Low", value: 31 },
    { range: "37.5-50%", label: "Low-Medium", value: 44 },
    { range: "50-62.5%", label: "Medium", value: 56 },
    { range: "62.5-75%", label: "Medium-High", value: 69 },
    { range: "75-87.5%", label: "High", value: 81 },
    { range: "87.5-100%", label: "Critical", value: 94 },
  ]

  return (
    <div className="bg-white p-4 rounded-lg shadow-sm border">
      <h3 className="text-sm font-semibold mb-3">Risk Level Legend</h3>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
        {riskLevels.map((level) => (
          <div key={level.label} className="flex items-center gap-2">
            <Badge className={`${getRiskBadgeStyles(level.value)} text-xs`}>{level.label}</Badge>
            <span className="text-xs text-gray-600">{level.range}</span>
          </div>
        ))}
      </div>
    </div>
  )
}
[V0_FILE]typescriptreact:file="lib/types.ts" isEdit="true" isMerged="true"
export interface Task {
  id: string
  ticket: string
  cis_control: number
  project_action: string
  summary: string
  description: string
  risk: string
  impact: string
  raw_probability: number
  raw_impact: number
  raw_risk: number
  avoid: number
  mitigate: number
  transfer: number
  accept: number | null
  treatment: string
  treated_probability: number
  treated_impact: number
  current_risk: number
  next_review: string
  department: string
  owner: string
  coordinator: string
  technician: string
  creation_date: string
  status: TaskStatus
  last_check: string
  comments: string
  completion_date?: string // Nueva propiedad para la fecha de completado
}

export type TaskStatus =
  | "Pending Ticket"
  | "Pending"
  | "Scheduled"
  | "Request for Authorization"
  | "In Progress"
  | "Implementation In Progress"
  | "Completed 2025" // Nuevo estado
  | "Completed 2024" // Nuevo estado
  | "Closed" // Mantenemos este para compatibilidad con datos existentes

export type RiskLevelFilter =
  | "All"
  | "Minimal"
  | "Very Low"
  | "Low"
  | "Low-Medium"
  | "Medium"
  | "Medium-High"
  | "High"
  | "Critical"

export interface TaskFilters {
  search: string
  status: TaskStatus | "All"
  department: string
  owner: string
  riskLevel: RiskLevelFilter
}

export type ViewMode = "kanban" | "table"

export interface PersonnelLists {
  owners: string[]
  coordinators: string[]
  technicians: string[]
}
[V0_FILE]typescriptreact:file="components/completion-date-helper.tsx" isMerged="true"
"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog"
import { Label } from "@/components/ui/label"
import { Calendar } from "@/components/ui/calendar"
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover"
import { format } from "date-fns"
import { es } from "date-fns/locale"
import { CalendarIcon } from "lucide-react"
import { cn } from "@/lib/utils"

interface CompletionDateHelperProps {
  onDateSelect: (date: Date) => void
}

export function CompletionDateHelper({ onDateSelect }: CompletionDateHelperProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [selectedDate, setSelectedDate] = useState<Date | undefined>(undefined)

  const handleConfirm = () => {
    if (selectedDate) {
      onDateSelect(selectedDate)
      setIsOpen(false)
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogTrigger asChild>
        <Button variant="outline" size="sm">
          Set Completion Date
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Select Completion Date</DialogTitle>
        </DialogHeader>
        <div className="grid gap-4 py-4">
          <div className="grid gap-2">
            <Label>Date</Label>
            <Popover>
              <PopoverTrigger asChild>
                <Button
                  variant="outline"
                  className={cn("w-full justify-start text-left font-normal", !selectedDate && "text-muted-foreground")}
                >
                  <CalendarIcon className="mr-2 h-4 w-4" />
                  {selectedDate ? format(selectedDate, "PPP", { locale: es }) : "Select date"}
                </Button>
              </PopoverTrigger>
              <PopoverContent className="w-auto p-0">
                <Calendar mode="single" selected={selectedDate} onSelect={setSelectedDate} initialFocus />
              </PopoverContent>
            </Popover>
          </div>
          <Button onClick={handleConfirm} disabled={!selectedDate}>
            Confirm
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  )
}
[V0_FILE]typescriptreact:file="components/import-preview.tsx" isMerged="true"
"use client"
import { Button } from "@/components/ui/button"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Badge } from "@/components/ui/badge"
import { getRiskBadgeStyles } from "@/lib/utils"
import type { Task } from "@/lib/types"

interface ImportPreviewProps {
  isOpen: boolean
  setIsOpen: (open: boolean) => void
  tasks: Task[]
  onConfirm: () => void
  onCancel: () => void
}

export function ImportPreview({ isOpen, setIsOpen, tasks, onConfirm, onCancel }: ImportPreviewProps) {
  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogContent className="max-w-5xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Vista previa de importación - {tasks.length} tareas</DialogTitle>
        </DialogHeader>

        <div className="border rounded-lg overflow-hidden mt-4">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Summary</TableHead>
                <TableHead>PROJECT/ACTION</TableHead>
                <TableHead>STATUS</TableHead>
                <TableHead>Current Risk</TableHead>
                <TableHead>OWNER</TableHead>
                <TableHead>DPT</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {tasks.map((task) => (
                <TableRow key={task.id || Math.random().toString()}>
                  <TableCell>{task.summary}</TableCell>
                  <TableCell>{task.project_action}</TableCell>
                  <TableCell>
                    <Badge variant="outline">{task.status}</Badge>
                  </TableCell>
                  <TableCell>
                    <Badge className={getRiskBadgeStyles(task.current_risk)}>{task.current_risk}%</Badge>
                  </TableCell>
                  <TableCell>{task.owner}</TableCell>
                  <TableCell>{task.department}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>

        <div className="flex justify-end space-x-2 mt-4">
          <Button variant="outline" onClick={onCancel}>
            Cancelar
          </Button>
          <Button onClick={onConfirm}>Importar {tasks.length} tareas</Button>
        </div>
      </DialogContent>
    </Dialog>
  )
}
[V0_FILE]typescriptreact:file="components/ui/toast.tsx" isMerged="true"
import * as React from "react"
import * as ToastPrimitives from "@radix-ui/react-toast"
import { cva, type VariantProps } from "class-variance-authority"
import { X } from "lucide-react"

import { cn } from "@/lib/utils"

const ToastProvider = ToastPrimitives.Provider

const ToastViewport = React.forwardRef<
  React.ElementRef<typeof ToastPrimitives.Viewport>,
  React.ComponentPropsWithoutRef<typeof ToastPrimitives.Viewport>
>(({ className, ...props }, ref) => (
  <ToastPrimitives.Viewport
    ref={ref}
    className={cn(
      "fixed top-0 z-[100] flex max-h-screen w-full flex-col-reverse p-4 sm:bottom-0 sm:right-0 sm:top-auto sm:flex-col md:max-w-[420px]",
      className,
    )}
    {...props}
  />
))
ToastViewport.displayName = ToastPrimitives.Viewport.displayName

const toastVariants = cva(
  "group pointer-events-auto relative flex w-full items-center justify-between space-x-4 overflow-hidden rounded-md border p-6 pr-8 shadow-lg transition-all data-[swipe=cancel]:translate-x-0 data-[swipe=end]:translate-x-[var(--radix-toast-swipe-end-x)] data-[swipe=move]:translate-x-[var(--radix-toast-swipe-move-x)] data-[swipe=move]:transition-none data-[state=open]:animate-in data-[state=closed]:animate-out data-[swipe=end]:animate-out data-[state=closed]:fade-out-80 data-[state=closed]:slide-out-to-right-full data-[state=open]:slide-in-from-top-full data-[state=open]:sm:slide-in-from-bottom-full",
  {
    variants: {
      variant: {
        default: "border bg-background text-foreground",
        destructive: "destructive group border-destructive bg-destructive text-destructive-foreground",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  },
)

const Toast = React.forwardRef<
  React.ElementRef<typeof ToastPrimitives.Root>,
  React.ComponentPropsWithoutRef<typeof ToastPrimitives.Root> & VariantProps<typeof toastVariants>
>(({ className, variant, ...props }, ref) => {
  return <ToastPrimitives.Root ref={ref} className={cn(toastVariants({ variant }), className)} {...props} />
})
Toast.displayName = ToastPrimitives.Root.displayName

const ToastAction = React.forwardRef<
  React.ElementRef<typeof ToastPrimitives.Action>,
  React.ComponentPropsWithoutRef<typeof ToastPrimitives.Action>
>(({ className, ...props }, ref) => (
  <ToastPrimitives.Action
    ref={ref}
    className={cn(
      "inline-flex h-8 shrink-0 items-center justify-center rounded-md border bg-transparent px-3 text-sm font-medium ring-offset-background transition-colors hover:bg-secondary focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 group-[.destructive]:border-muted/40 group-[.destructive]:hover:border-destructive/30 group-[.destructive]:hover:bg-destructive group-[.destructive]:hover:text-destructive-foreground group-[.destructive]:focus:ring-destructive",
      className,
    )}
    {...props}
  />
))
ToastAction.displayName = ToastPrimitives.Action.displayName

const ToastClose = React.forwardRef<
  React.ElementRef<typeof ToastPrimitives.Close>,
  React.ComponentPropsWithoutRef<typeof ToastPrimitives.Close>
>(({ className, ...props }, ref) => (
  <ToastPrimitives.Close
    ref={ref}
    className={cn(
      "absolute right-2 top-2 rounded-md p-1 text-foreground/50 opacity-0 transition-opacity hover:text-foreground focus:opacity-100 focus:outline-none focus:ring-2 group-hover:opacity-100 group-[.destructive]:text-red-300 group-[.destructive]:hover:text-red-50 group-[.destructive]:focus:ring-red-400 group-[.destructive]:focus:ring-offset-red-600",
      className,
    )}
    toast-close=""
    {...props}
  >
    <X className="h-4 w-4" />
  </ToastPrimitives.Close>
))
ToastClose.displayName = ToastPrimitives.Close.displayName

const ToastTitle = React.forwardRef<
  React.ElementRef<typeof ToastPrimitives.Title>,
  React.ComponentPropsWithoutRef<typeof ToastPrimitives.Title>
>(({ className, ...props }, ref) => (
  <ToastPrimitives.Title ref={ref} className={cn("text-sm font-semibold", className)} {...props} />
))
ToastTitle.displayName = ToastPrimitives.Title.displayName

const ToastDescription = React.forwardRef<
  React.ElementRef<typeof ToastPrimitives.Description>,
  React.ComponentPropsWithoutRef<typeof ToastPrimitives.Description>
>(({ className, ...props }, ref) => (
  <ToastPrimitives.Description ref={ref} className={cn("text-sm opacity-90", className)} {...props} />
))
ToastDescription.displayName = ToastPrimitives.Description.displayName

type ToastProps = React.ComponentPropsWithoutRef<typeof Toast>

type ToastActionElement = React.ReactElement<typeof ToastAction>

export {
  type ToastProps,
  type ToastActionElement,
  ToastProvider,
  ToastViewport,
  Toast,
  ToastTitle,
  ToastDescription,
  ToastClose,
  ToastAction,
}
[V0_FILE]typescriptreact:file="components/ui/toaster.tsx" isMerged="true"
"use client"

import { Toast, ToastClose, ToastDescription, ToastProvider, ToastTitle, ToastViewport } from "@/components/ui/toast"
import { useToast } from "@/components/ui/use-toast"

export function Toaster() {
  const { toasts } = useToast()

  return (
    <ToastProvider>
      {toasts.map(({ id, title, description, action, ...props }) => (
        <Toast key={id} {...props}>
          <div className="grid gap-1">
            {title && <ToastTitle>{title}</ToastTitle>}
            {description && <ToastDescription>{description}</ToastDescription>}
          </div>
          {action}
          <ToastClose />
        </Toast>
      ))}
      <ToastViewport />
    </ToastProvider>
  )
}
[V0_FILE]typescriptreact:file="components/ui/use-toast.ts" isMerged="true"
"use client"

// Inspired by react-hot-toast library
import * as React from "react"

import type { ToastActionElement, ToastProps } from "@/components/ui/toast"

const TOAST_LIMIT = 5
const TOAST_REMOVE_DELAY = 5000

type ToasterToast = ToastProps & {
  id: string
  title?: React.ReactNode
  description?: React.ReactNode
  action?: ToastActionElement
}

const actionTypes = {
  ADD_TOAST: "ADD_TOAST",
  UPDATE_TOAST: "UPDATE_TOAST",
  DISMISS_TOAST: "DISMISS_TOAST",
  REMOVE_TOAST: "REMOVE_TOAST",
} as const

let count = 0

function genId() {
  count = (count + 1) % Number.MAX_SAFE_INTEGER
  return count.toString()
}

type ActionType = typeof actionTypes

type Action =
  | {
      type: ActionType["ADD_TOAST"]
      toast: ToasterToast
    }
  | {
      type: ActionType["UPDATE_TOAST"]
      toast: Partial<ToasterToast>
    }
  | {
      type: ActionType["DISMISS_TOAST"]
      toastId?: string
    }
  | {
      type: ActionType["REMOVE_TOAST"]
      toastId?: string
    }

interface State {
  toasts: ToasterToast[]
}

const toastTimeouts = new Map<string, ReturnType<typeof setTimeout>>()

const addToRemoveQueue = (toastId: string) => {
  if (toastTimeouts.has(toastId)) {
    return
  }

  const timeout = setTimeout(() => {
    toastTimeouts.delete(toastId)
    dispatch({
      type: "REMOVE_TOAST",
      toastId: toastId,
    })
  }, TOAST_REMOVE_DELAY)

  toastTimeouts.set(toastId, timeout)
}

export const reducer = (state: State, action: Action): State => {
  switch (action.type) {
    case "ADD_TOAST":
      return {
        ...state,
        toasts: [action.toast, ...state.toasts].slice(0, TOAST_LIMIT),
      }

    case "UPDATE_TOAST":
      return {
        ...state,
        toasts: state.toasts.map((t) => (t.id === action.toast.id ? { ...t, ...action.toast } : t)),
      }

    case "DISMISS_TOAST": {
      const { toastId } = action

      // ! Side effects ! - This could be extracted into a dismissToast() action,
      // but I'll keep it here for simplicity
      if (toastId) {
        addToRemoveQueue(toastId)
      } else {
        state.toasts.forEach((toast) => {
          addToRemoveQueue(toast.id)
        })
      }

      return {
        ...state,
        toasts: state.toasts.map((t) =>
          t.id === toastId || toastId === undefined
            ? {
                ...t,
                open: false,
              }
            : t,
        ),
      }
    }
    case "REMOVE_TOAST":
      if (action.toastId === undefined) {
        return {
          ...state,
          toasts: [],
        }
      }
      return {
        ...state,
        toasts: state.toasts.filter((t) => t.id !== action.toastId),
      }
  }
}

const listeners: Array<(state: State) => void> = []

let memoryState: State = { toasts: [] }

function dispatch(action: Action) {
  memoryState = reducer(memoryState, action)
  listeners.forEach((listener) => {
    listener(memoryState)
  })
}

type Toast = Omit<ToasterToast, "id">

function toast({ ...props }: Toast) {
  const id = genId()

  const update = (props: ToasterToast) =>
    dispatch({
      type: "UPDATE_TOAST",
      toast: { ...props, id },
    })
  const dismiss = () => dispatch({ type: "DISMISS_TOAST", toastId: id })

  dispatch({
    type: "ADD_TOAST",
    toast: {
      ...props,
      id,
      open: true,
      onOpenChange: (open) => {
        if (!open) dismiss()
      },
    },
  })

  return {
    id: id,
    dismiss,
    update,
  }
}

function useToast() {
  const [state, setState] = React.useState<State>(memoryState)

  React.useEffect(() => {
    listeners.push(setState)
    return () => {
      const index = listeners.indexOf(setState)
      if (index > -1) {
        listeners.splice(index, 1)
      }
    }
  }, [state])

  return {
    ...state,
    toast,
    dismiss: (toastId?: string) => dispatch({ type: "DISMISS_TOAST", toastId }),
  }
}

export { useToast, toast }
[V0_FILE]typescriptreact:file="app/layout.tsx" isMerged="true"
import type React from "react"
import "@/app/globals.css"
import { Toaster } from "@/components/ui/toaster"

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        {children}
        <Toaster />
      </body>
    </html>
  )
}
[V0_FILE]python:file="backend/requirements.txt" isMerged="true"
fastapi==0.109.0
uvicorn[standard]==0.27.0
sqlalchemy==2.0.25
psycopg2-binary==2.9.9
python-dotenv==1.0.0
pydantic==2.5.3
alembic==1.13.1
python-multipart==0.0.6
[V0_FILE]python:file="backend/.env.example" isMerged="true"
DATABASE_URL=postgresql://user:password@localhost/cybersec_tasks
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
[V0_FILE]python:file="backend/app/__init__.py" isMerged="true"
# FastAPI Cybersecurity Task Management Backend
[V0_FILE]python:file="backend/app/database.py" isMerged="true"
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@localhost/cybersec_tasks")

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
[V0_FILE]python:file="backend/app/models.py" isMerged="true"
from sqlalchemy import Column, Integer, String, Float, DateTime, Text, ForeignKey, Table
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base

# Association tables for many-to-many relationships
task_owners = Table('task_owners',
    Base.metadata,
    Column('task_id', String, ForeignKey('tasks.id')),
    Column('personnel_id', Integer, ForeignKey('personnel.id'))
)

task_coordinators = Table('task_coordinators',
    Base.metadata,
    Column('task_id', String, ForeignKey('tasks.id')),
    Column('personnel_id', Integer, ForeignKey('personnel.id'))
)

task_technicians = Table('task_technicians',
    Base.metadata,
    Column('task_id', String, ForeignKey('tasks.id')),
    Column('personnel_id', Integer, ForeignKey('personnel.id'))
)

class Task(Base):
    __tablename__ = "tasks"

    id = Column(String, primary_key=True, index=True)
    ticket = Column(String, nullable=True)
    cis_control = Column(Integer)
    project_action = Column(String)
    summary = Column(String)
    description = Column(Text)
    risk = Column(String)
    impact = Column(String)
    raw_probability = Column(Float)
    raw_impact = Column(Float)
    raw_risk = Column(Float)
    avoid = Column(Float, default=0)
    mitigate = Column(Float, default=0)
    transfer = Column(Float, default=0)
    accept = Column(Float, nullable=True)
    treatment = Column(Text)
    treated_probability = Column(Float)
    treated_impact = Column(Float)
    current_risk = Column(Float)
    next_review = Column(String)
    department = Column(String)
    owner = Column(String)  # Mantenemos como string para compatibilidad
    coordinator = Column(String)  # Mantenemos como string para compatibilidad
    technician = Column(String)  # Mantenemos como string para compatibilidad
    creation_date = Column(String)
    status = Column(String)
    last_check = Column(String)
    comments = Column(Text)
    completion_date = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class Personnel(Base):
    __tablename__ = "personnel"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    type = Column(String)  # 'owner', 'coordinator', 'technician'
    created_at = Column(DateTime, default=datetime.utcnow)
[V0_FILE]python:file="backend/app/schemas.py" isMerged="true"
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class TaskBase(BaseModel):
    ticket: Optional[str] = None
    cis_control: int
    project_action: str
    summary: str
    description: str
    risk: str
    impact: str
    raw_probability: float
    raw_impact: float
    raw_risk: float
    avoid: float = 0
    mitigate: float = 0
    transfer: float = 0
    accept: Optional[float] = None
    treatment: str
    treated_probability: float
    treated_impact: float
    current_risk: float
    next_review: str
    department: str
    owner: str
    coordinator: str
    technician: str
    creation_date: str
    status: str
    last_check: str
    comments: str
    completion_date: Optional[str] = None

class TaskCreate(TaskBase):
    pass

class TaskUpdate(TaskBase):
    pass

class Task(TaskBase):
    id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class PersonnelBase(BaseModel):
    name: str
    type: str  # 'owner', 'coordinator', 'technician'

class PersonnelCreate(PersonnelBase):
    pass

class Personnel(PersonnelBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True

class PersonnelList(BaseModel):
    owners: List[str]
    coordinators: List[str]
    technicians: List[str]
[V0_FILE]python:file="backend/app/crud.py" isMerged="true"
from sqlalchemy.orm import Session
from . import models, schemas
from typing import List, Optional
import uuid
from datetime import datetime

def get_task(db: Session, task_id: str):
    return db.query(models.Task).filter(models.Task.id == task_id).first()

def get_tasks(db: Session, skip: int = 0, limit: int = 1000):
    return db.query(models.Task).offset(skip).limit(limit).all()

def get_in_progress_tasks(db: Session):
    return db.query(models.Task).filter(
        ~models.Task.status.in_(['Completed 2024', 'Completed 2025', 'Closed'])
    ).all()

def get_closed_tasks(db: Session):
    return db.query(models.Task).filter(
        models.Task.status.in_(['Completed 2024', 'Completed 2025', 'Closed'])
    ).all()

def create_task(db: Session, task: schemas.TaskCreate):
    db_task = models.Task(
        id=f"task_{int(datetime.now().timestamp())}_{uuid.uuid4().hex[:10]}",
        **task.dict()
    )
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task

def update_task(db: Session, task_id: str, task: schemas.TaskUpdate):
    db_task = get_task(db, task_id)
    if db_task:
        for key, value in task.dict().items():
            setattr(db_task, key, value)
        db_task.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(db_task)
    return db_task

def delete_task(db: Session, task_id: str):
    db_task = get_task(db, task_id)
    if db_task:
        db.delete(db_task)
        db.commit()
        return True
    return False

def get_personnel(db: Session, personnel_type: Optional[str] = None):
    query = db.query(models.Personnel)
    if personnel_type:
        query = query.filter(models.Personnel.type == personnel_type)
    return query.all()

def create_personnel(db: Session, personnel: schemas.PersonnelCreate):
    db_personnel = models.Personnel(**personnel.dict())
    db.add(db_personnel)
    db.commit()
    db.refresh(db_personnel)
    return db_personnel

def delete_personnel(db: Session, personnel_id: int):
    db_personnel = db.query(models.Personnel).filter(models.Personnel.id == personnel_id).first()
    if db_personnel:
        db.delete(db_personnel)
        db.commit()
        return True
    return False
[V0_FILE]python:file="backend/app/main.py" isMerged="true"
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List
import json
from . import crud, models, schemas
from .database import SessionLocal, engine, get_db

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Cybersecurity Task Management API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],  # Adjust for your frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "Cybersecurity Task Management API"}

# Task endpoints
@app.get("/api/tasks", response_model=dict)
def read_tasks(db: Session = Depends(get_db)):
    in_progress = crud.get_in_progress_tasks(db)
    closed = crud.get_closed_tasks(db)
    all_tasks = in_progress + closed
    
    return {
        "inProgress": in_progress,
        "closed": closed,
        "all": all_tasks
    }

@app.post("/api/tasks", response_model=schemas.Task)
def create_task(task: schemas.TaskCreate, db: Session = Depends(get_db)):
    return crud.create_task(db=db, task=task)

@app.put("/api/tasks/{task_id}", response_model=schemas.Task)
def update_task(task_id: str, task: schemas.TaskUpdate, db: Session = Depends(get_db)):
    db_task = crud.update_task(db, task_id, task)
    if db_task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    return db_task

@app.delete("/api/tasks/{task_id}")
def delete_task(task_id: str, db: Session = Depends(get_db)):
    success = crud.delete_task(db, task_id)
    if not success:
        raise HTTPException(status_code=404, detail="Task not found")
    return {"success": True}

# Personnel endpoints
@app.get("/api/personnel", response_model=schemas.PersonnelList)
def read_personnel(db: Session = Depends(get_db)):
    personnel = crud.get_personnel(db)
    
    owners = [p.name for p in personnel if p.type == "owners"]
    coordinators = [p.name for p in personnel if p.type == "coordinators"]
    technicians = [p.name for p in personnel if p.type == "technicians"]
    
    return {
        "owners": owners,
        "coordinators": coordinators,
        "technicians": technicians
    }

@app.post("/api/personnel", response_model=schemas.PersonnelList)
def create_personnel(personnel: schemas.PersonnelCreate, db: Session = Depends(get_db)):
    # Check if personnel already exists
    existing = db.query(models.Personnel).filter(
        models.Personnel.name == personnel.name,
        models.Personnel.type == personnel.type
    ).first()
    
    if not existing:
        crud.create_personnel(db, personnel)
    
    # Return updated list
    return read_personnel(db)

@app.delete("/api/personnel/{personnel_id}")
def delete_personnel(personnel_id: int, db: Session = Depends(get_db)):
    success = crud.delete_personnel(db, personnel_id)
    if not success:
        raise HTTPException(status_code=404, detail="Personnel not found")
    return {"success": True}

# Export endpoint
@app.get("/api/tasks/export")
def export_tasks(format: str = "json", db: Session = Depends(get_db)):
    tasks = crud.get_tasks(db)
    
    if format == "json":
        return tasks
    elif format == "csv":
        # Implement CSV export logic here
        pass
    
# Initialize database with example data
@app.post("/api/init")
def initialize_database(db: Session = Depends(get_db)):
    # Check if database is empty
    existing_tasks = crud.get_tasks(db)
    if len(existing_tasks) == 0:
        # Load example tasks
        with open("example_tasks.json", "r") as f:
            example_tasks = json.load(f)
        
        for task_data in example_tasks:
            task = schemas.TaskCreate(**task_data)
            crud.create_task(db, task)
        
        # Create default personnel
        default_personnel = [
            {"name": "Juan Pérez", "type": "owners"},
            {"name": "María García", "type": "owners"},
            {"name": "Carlos López", "type": "owners"},
            {"name": "Laura García", "type": "coordinators"},
            {"name": "Ana Martínez", "type": "coordinators"},
            {"name": "Pedro Rodríguez", "type": "coordinators"},
            {"name": "Carlos López", "type": "technicians"},
            {"name": "Miguel Torres", "type": "technicians"},
            {"name": "Sofia Hernández", "type": "technicians"},
        ]
        
        for p in default_personnel:
            personnel = schemas.PersonnelCreate(**p)
            existing = db.query(models.Personnel).filter(
                models.Personnel.name == personnel.name,
                models.Personnel.type == personnel.type
            ).first()
            if not existing:
                crud.create_personnel(db, personnel)
    
    return {"success": True, "message": "Database initialized"}
[V0_FILE]python:file="backend/alembic.ini" isMerged="true"
# A generic, single database configuration.

[alembic]
# path to migration scripts
script_location = alembic

# template used to generate migration file names; The default value is %%(rev)s_%%(slug)s
# Uncomment the line below if you want the files to be prepended with date and time
# file_template = %%(year)d%%(month).2d%%(day).2d_%%(hour).2d%%(minute).2d-%%(rev)s_%%(slug)s

# sys.path path, will be prepended to sys.path if present.
# defaults to the current working directory.
prepend_sys_path = .

# timezone to use when rendering the date within the migration file
# as well as the filename.
# If specified, requires the python-dateutil library
# timezone =

# max length of characters to apply to the
# "slug" field
# truncate_slug_length = 40

# set to 'true' to run the environment during
# the 'revision' command, regardless of autogenerate
# revision_environment = false

# set to 'true' to allow .pyc and .pyo files without
# a source .py file to be detected as revisions in the
# versions/ directory
# sourceless = false

# version location specification; This defaults
# to alembic/versions.  When using multiple version
# directories, initial revisions must be specified with --version-path.
# The path separator used here should be the separator specified by "version_path_separator" below.
# version_locations = %(here)s/bar:%(here)s/bat:alembic/versions

# version path separator; As mentioned above, this is the character used to split
# version_locations. The default within new alembic.ini files is "os", which uses os.pathsep.
# If this key is omitted entirely, it falls back to the legacy behavior of splitting on spaces and/or commas.
# Valid values for version_path_separator are:
#
# version_path_separator = :
# version_path_separator = ;
# version_path_separator = space
version_path_separator = os  # Use os.pathsep.
# set to 'true' to search source files recursively
# in each "version_locations" directory
# new in Alembic version 1.10
# recursive_version_locations = false

# the output encoding used when revision files
# are written from script.py.mako
# output_encoding = utf-8

sqlalchemy.url = postgresql://user:password@localhost/cybersec_tasks


[post_write_hooks]
# post_write_hooks defines scripts or Python functions that are run
# on newly generated revision scripts.  See the documentation for further
# detail and examples

# format using "black" - use the console_scripts runner, against the "black" entrypoint
# hooks = black
# black.type = console_scripts
# black.entrypoint = black
# black.options = -l 79 REVISION_SCRIPT_FILENAME

# lint with attempts to fix using "ruff" - use the exec runner, execute a binary
# hooks = ruff
# ruff.type = exec
# ruff.executable = %(here)s/.venv/bin/ruff
# ruff.options = --fix REVISION_SCRIPT_FILENAME

# Logging configuration
[loggers]
keys = root,sqlalchemy,alembic

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = WARN
handlers = console
qualname =

[logger_sqlalchemy]
level = WARN
handlers =
qualname = sqlalchemy.engine

[logger_alembic]
level = INFO
handlers =
qualname = alembic

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(levelname)-5.5s [%(name)s] %(message)s
datefmt = %H:%M:%S
[V0_FILE]python:file="backend/run.py" isMerged="true"
import uvicorn

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
[V0_FILE]shellscript:file="backend/README.md" isMerged="true"
# Cybersecurity Task Management Backend

## Setup

1. Install PostgreSQL
2. Create a virtual environment:
   \`\`\`bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   \`\`\`

3. Install dependencies:
   \`\`\`bash
   pip install -r requirements.txt
   \`\`\`

4. Create a `.env` file based on `.env.example`

5. Run database migrations:
   \`\`\`bash
   alembic upgrade head
   \`\`\`

6. Run the server:
   \`\`\`bash
   python run.py
   \`\`\`

## Docker Setup

1. Run with Docker Compose:
   \`\`\`bash
   docker-compose up -d
   \`\`\`

This will start:
- PostgreSQL database on port 5432
- FastAPI backend on port 8000
- Next.js frontend on port 3000
[V0_FILE]python:file="backend/example_tasks.json" isMerged="true"
[
  {
    "ticket": "CRQ000123456",
    "cis_control": 1,
    "project_action": "Inventario de Activos",
    "summary": "Actualizar inventario de servidores",
    "description": "Realizar un inventario completo de todos los servidores físicos y virtuales en el datacenter principal",
    "risk": "Activos no gestionados",
    "impact": "Posibles vulnerabilidades no detectadas",
    "raw_probability": 70,
    "raw_impact": 80,
    "raw_risk": 56,
    "avoid": 0,
    "mitigate": 40,
    "transfer": 0,
    "accept": null,
    "treatment": "Implementar herramienta automatizada de descubrimiento de activos",
    "treated_probability": 30,
    "treated_impact": 60,
    "current_risk": 18,
    "next_review": "2025-08-15",
    "department": "Infraestructura",
    "owner": "Juan Pérez",
    "coordinator": "Laura García",
    "technician": "Carlos López",
    "creation_date": "2025-05-01",
    "status": "In Progress",
    "last_check": "2025-05-15",
    "comments": "Se ha completado el 60% del inventario"
  },
  {
    "ticket": "CRQ000123457",
    "cis_control": 3,
    "project_action": "Protección de Datos",
    "summary": "Implementar cifrado de datos en reposo",
    "description": "Implementar cifrado para todos los datos sensibles almacenados en bases de datos corporativas",
    "risk": "Exposición de datos sensibles",
    "impact": "Violación de privacidad y posibles sanciones",
    "raw_probability": 60,
    "raw_impact": 90,
    "raw_risk": 54,
    "avoid": 0,
    "mitigate": 30,
    "transfer": 10,
    "accept": null,
    "treatment": "Implementar solución de cifrado transparente para bases de datos",
    "treated_probability": 20,
    "treated_impact": 70,
    "current_risk": 14,
    "next_review": "2025-07-20",
    "department": "Seguridad",
    "owner": "María García",
    "coordinator": "Pedro Rodríguez",
    "technician": "Sofia Hernández",
    "creation_date": "2025-05-02",
    "status": "Scheduled",
    "last_check": "2025-05-16",
    "comments": "Programado para implementación el 15/06/2025"
  },
  {
    "ticket": "CRQ000123458",
    "cis_control": 7,
    "project_action": "Gestión de Vulnerabilidades",
    "summary": "Implementar escaneo continuo de vulnerabilidades",
    "description": "Configurar escaneos automáticos semanales de vulnerabilidades en todos los sistemas críticos",
    "risk": "Vulnerabilidades no detectadas",
    "impact": "Posible explotación de vulnerabilidades",
    "raw_probability": 80,
    "raw_impact": 85,
    "raw_risk": 68,
    "avoid": 0,
    "mitigate": 50,
    "transfer": 0,
    "accept": null,
    "treatment": "Implementar Qualys para escaneo continuo y automatizar la generación de tickets para remediación",
    "treated_probability": 30,
    "treated_impact": 70,
    "current_risk": 21,
    "next_review": "2025-06-30",
    "department": "Seguridad",
    "owner": "Carlos López",
    "coordinator": "Ana Martínez",
    "technician": "Miguel Torres",
    "creation_date": "2025-05-03",
    "status": "Implementation In Progress",
    "last_check": "2025-05-17",
    "comments": "Fase 1 completada, configurando escaneos automáticos"
  },
  {
    "ticket": "CRQ000123459",
    "cis_control": 10,
    "project_action": "Defensa contra Malware",
    "summary": "Actualizar solución antimalware",
    "description": "Actualizar la solución antimalware corporativa a la última versión y asegurar cobertura en todos los endpoints",
    "risk": "Infección por malware",
    "impact": "Pérdida de datos, interrupción de servicios",
    "raw_probability": 75,
    "raw_impact": 80,
    "raw_risk": 60,
    "avoid": 0,
    "mitigate": 45,
    "transfer": 0,
    "accept": null,
    "treatment": "Actualizar a la versión más reciente y verificar la cobertura en todos los endpoints",
    "treated_probability": 25,
    "treated_impact": 60,
    "current_risk": 15,
    "next_review": "2025-07-15",
    "department": "Operaciones",
    "owner": "Juan Pérez",
    "coordinator": "Laura García",
    "technician": "Carlos López",
    "creation_date": "2025-05-04",
    "status": "Request for Authorization",
    "last_check": "2025-05-18",
    "comments": "Esperando aprobación del presupuesto"
  },
  {
    "ticket": "CRQ000123460",
    "cis_control": 4,
    "project_action": "Configuración Segura",
    "summary": "Implementar gestión de configuración segura",
    "description": "Desarrollar e implementar líneas base de configuración segura para todos los sistemas operativos utilizados",
    "risk": "Configuraciones inseguras",
    "impact": "Vulnerabilidades explotables",
    "raw_probability": 85,
    "raw_impact": 75,
    "raw_risk": 64,
    "avoid": 0,
    "mitigate": 55,
    "transfer": 0,
    "accept": null,
    "treatment": "Implementar CIS Benchmarks y automatizar verificación de cumplimiento",
    "treated_probability": 30,
    "treated_impact": 60,
    "current_risk": 18,
    "next_review": "2025-08-01",
    "department": "Infraestructura",
    "owner": "María García",
    "coordinator": "Pedro Rodríguez",
    "technician": "Miguel Torres",
    "creation_date": "2025-05-05",
    "status": "Pending",
    "last_check": "2025-05-19",
    "comments": "Pendiente de asignación de recursos"
  },
  {
    "ticket": "CRQ000123461",
    "cis_control": 6,
    "project_action": "Gestión de Accesos",
    "summary": "Implementar autenticación multifactor",
    "description": "Implementar MFA para todos los accesos administrativos a sistemas críticos",
    "risk": "Compromiso de credenciales",
    "impact": "Acceso no autorizado a sistemas críticos",
    "raw_probability": 70,
    "raw_impact": 90,
    "raw_risk": 63,
    "avoid": 0,
    "mitigate": 50,
    "transfer": 0,
    "accept": null,
    "treatment": "Implementar solución MFA basada en tokens y biometría",
    "treated_probability": 20,
    "treated_impact": 80,
    "current_risk": 16,
    "next_review": "2025-06-15",
    "department": "Seguridad",
    "owner": "Carlos López",
    "coordinator": "Ana Martínez",
    "technician": "Sofia Hernández",
    "creation_date": "2025-05-06",
    "status": "Completed 2025",
    "last_check": "2025-05-20",
    "completion_date": "2025-05-20",
    "comments": "Implementado con éxito en todos los sistemas críticos"
  },
  {
    "ticket": "CRQ000123462",
    "cis_control": 8,
    "project_action": "Gestión de Logs",
    "summary": "Centralizar logs de seguridad",
    "description": "Implementar un SIEM para centralizar y correlacionar logs de seguridad de todos los sistemas",
    "risk": "Detección tardía de incidentes",
    "impact": "Mayor tiempo de respuesta ante incidentes",
    "raw_probability": 65,
    "raw_impact": 75,
    "raw_risk": 49,
    "avoid": 0,
    "mitigate": 35,
    "transfer": 0,
    "accept": null,
    "treatment": "Implementar Splunk Enterprise Security y configurar reglas de correlación",
    "treated_probability": 25,
    "treated_impact": 60,
    "current_risk": 15,
    "next_review": "2025-07-30",
    "department": "Operaciones",
    "owner": "María García",
    "coordinator": "Laura García",
    "technician": "Miguel Torres",
    "creation_date": "2025-05-07",
    "status": "Completed 2024",
    "last_check": "2024-12-15",
    "completion_date": "2024-12-15",
    "comments": "Implementado en diciembre 2024, funcionando correctamente"
  },
  {
    "ticket": "CRQ000123463",
    "cis_control": 17,
    "project_action": "Gestión de Incidentes",
    "summary": "Actualizar plan de respuesta a incidentes",
    "description": "Revisar y actualizar el plan de respuesta a incidentes de seguridad",
    "risk": "Respuesta ineficiente a incidentes",
    "impact": "Mayor impacto de los incidentes",
    "raw_probability": 60,
    "raw_impact": 85,
    "raw_risk": 51,
    "avoid": 0,
    "mitigate": 30,
    "transfer": 10,
    "accept": null,
    "treatment": "Actualizar procedimientos, realizar simulacros y capacitar al personal",
    "treated_probability": 30,
    "treated_impact": 70,
    "current_risk": 21,
    "next_review": "2025-09-01",
    "department": "Seguridad",
    "owner": "Juan Pérez",
    "coordinator": "Pedro Rodríguez",
    "technician": "Carlos López",
    "creation_date": "2025-05-08",
    "status": "In Progress",
    "last_check": "2025-05-22",
    "comments": "Revisión en curso, 40% completado"
  },
  {
    "ticket": "CRQ000123464",
    "cis_control": 12,
    "project_action": "Gestión de Red",
    "summary": "Segmentar red corporativa",
    "description": "Implementar segmentación de red basada en roles y funciones de negocio",
    "risk": "Movimiento lateral en caso de compromiso",
    "impact": "Propagación de amenazas en la red",
    "raw_probability": 75,
    "raw_impact": 85,
    "raw_risk": 64,
    "avoid": 0,
    "mitigate": 45,
    "transfer": 0,
    "accept": null,
    "treatment": "Implementar VLANs y firewalls internos para segmentar la red",
    "treated_probability": 30,
    "treated_impact": 70,
    "current_risk": 21,
    "next_review": "2025-08-15",
    "department": "Infraestructura",
    "owner": "Carlos López",
    "coordinator": "Ana Martínez",
    "technician": "Miguel Torres",
    "creation_date": "2025-05-09",
    "status": "Pending Ticket",
    "last_check": "2025-05-23",
    "comments": "Esperando creación del ticket en el sistema"
  },
  {
    "ticket": "CRQ000123465",
    "cis_control": 19,
    "project_action": "Compliance",
    "summary": "Auditoría de cumplimiento PCI-DSS",
    "description": "Realizar auditoría interna de cumplimiento PCI-DSS antes de la certificación oficial",
    "risk": "Incumplimiento regulatorio",
    "impact": "Sanciones económicas y pérdida de reputación",
    "raw_probability": 55,
    "raw_impact": 95,
    "raw_risk": 52,
    "avoid": 0,
    "mitigate": 35,
    "transfer": 10,
    "accept": null,
    "treatment": "Contratar consultoría especializada para pre-auditoría y remediar hallazgos",
    "treated_probability": 20,
    "treated_impact": 90,
    "current_risk": 18,
    "next_review": "2025-06-30",
    "department": "Seguridad",
    "owner": "María García",
    "coordinator": "Pedro Rodríguez",
    "technician": "Sofia Hernández",
    "creation_date": "2025-05-10",
    "status": "Scheduled",
    "last_check": "2025-05-24",
    "comments": "Auditoría programada para el 15/07/2025"
  },
  {
    "ticket": "CRQ000123466",
    "cis_control": 5,
    "project_action": "Gestión de Cuentas",
    "summary": "Implementar revisión periódica de privilegios",
    "description": "Establecer un proceso trimestral de revisión de privilegios para todas las cuentas con acceso a sistemas críticos",
    "risk": "Acumulación de privilegios",
    "impact": "Acceso excesivo a sistemas críticos",
    "raw_probability": 80,
    "raw_impact": 70,
    "raw_risk": 56,
    "avoid": 0,
    "mitigate": 40,
    "transfer": 0,
    "accept": null,
    "treatment": "Implementar herramienta de gestión de identidades y accesos (IAM) con workflows de aprobación",
    "treated_probability": 30,
    "treated_impact": 50,
    "current_risk": 15,
    "next_review": "2025-07-10",
    "department": "Seguridad",
    "owner": "Juan Pérez",
    "coordinator": "Laura García",
    "technician": "Sofia Hernández",
    "creation_date": "2025-05-11",
    "status": "Implementation In Progress",
    "last_check": "2025-05-25",
    "comments": "Fase de implementación de la herramienta IAM en curso"
  },
  {
    "ticket": "CRQ000123467",
    "cis_control": 14,
    "project_action": "SOC",
    "summary": "Implementar monitoreo 24/7",
    "description": "Establecer un Centro de Operaciones de Seguridad (SOC) con monitoreo 24/7 para detección temprana de incidentes",
    "risk": "Detección tardía de incidentes",
    "impact": "Mayor tiempo de respuesta y potencial impacto",
    "raw_probability": 75,
    "raw_impact": 90,
    "raw_risk": 68,
    "avoid": 0,
    "mitigate": 50,
    "transfer": 10,
    "accept": null,
    "treatment": "Contratar servicio de SOC gestionado con SLAs de respuesta",
    "treated_probability": 25,
    "treated_impact": 70,
    "current_risk": 18,
    "next_review": "2025-08-20",
    "department": "Seguridad",
    "owner": "María García",
    "coordinator": "Pedro Rodríguez",
    "technician": "Carlos López",
    "creation_date": "2025-05-12",
    "status": "Request for Authorization",
    "last_check": "2025-05-26",
    "comments": "Esperando aprobación del presupuesto para el servicio de SOC"
  },
  {
    "ticket": "CRQ000123468",
    "cis_control": 11,
    "project_action": "Recuperación de Datos",
    "summary": "Implementar solución de backup en la nube",
    "description": "Implementar solución de backup en la nube para datos críticos con capacidad de recuperación rápida",
    "risk": "Pérdida de datos críticos",
    "impact": "Interrupción de operaciones y pérdida financiera",
    "raw_probability": 60,
    "raw_impact": 95,
    "raw_risk": 57,
    "avoid": 0,
    "mitigate": 40,
    "transfer": 10,
    "accept": null,
    "treatment": "Implementar solución de backup en la nube con replicación geográfica y pruebas de recuperación mensuales",
    "treated_probability": 20,
    "treated_impact": 80,
    "current_risk": 16,
    "next_review": "2025-06-25",
    "department": "Infraestructura",
    "owner": "Carlos López",
    "coordinator": "Ana Martínez",
    "technician": "Miguel Torres",
    "creation_date": "2025-05-13",
    "status": "Completed 2025",
    "last_check": "2025-05-27",
    "completion_date": "2025-05-27",
    "comments": "Implementación completada y pruebas de recuperación exitosas"
  },
  {
    "ticket": "CRQ000123469",
    "cis_control": 9,
    "project_action": "Protección de Navegadores",
    "summary": "Implementar filtrado de contenido web",
    "description": "Implementar solución de filtrado de contenido web para proteger contra sitios maliciosos y phishing",
    "risk": "Infección por malware vía web",
    "impact": "Compromiso de sistemas y datos",
    "raw_probability": 85,
    "raw_impact": 75,
    "raw_risk": 64,
    "avoid": 0,
    "mitigate": 50,
    "transfer": 0,
    "accept": null,
    "treatment": "Implementar Cisco Umbrella para filtrado DNS y protección contra amenazas web",
    "treated_probability": 30,
    "treated_impact": 60,
    "current_risk": 18,
    "next_review": "2025-07-05",
    "department": "Seguridad",
    "owner": "Juan Pérez",
    "coordinator": "Laura García",
    "technician": "Sofia Hernández",
    "creation_date": "2025-05-14",
    "status": "Completed 2024",
    "last_check": "2024-11-20",
    "completion_date": "2024-11-20",
    "comments": "Implementado en noviembre 2024, funcionando correctamente"
  },
  {
    "ticket": "CRQ000123470",
    "cis_control": 16,
    "project_action": "Seguridad de Aplicaciones",
    "summary": "Implementar análisis estático de código",
    "description": "Implementar análisis estático de código (SAST) en el pipeline de CI/CD para detectar vulnerabilidades tempranamente",
    "risk": "Vulnerabilidades en aplicaciones",
    "impact": "Explotación de vulnerabilidades en producción",
    "raw_probability": 70,
    "raw_impact": 85,
    "raw_risk": 60,
    "avoid": 0,
    "mitigate": 45,
    "transfer": 0,
    "accept": null,
    "treatment": "Implementar SonarQube y Checkmarx en el pipeline de CI/CD",
    "treated_probability": 25,
    "treated_impact": 70,
    "current_risk": 18,
    "next_review": "2025-08-10",
    "department": "Operaciones",
    "owner": "María García",
    "coordinator": "Pedro Rodríguez",
    "technician": "Carlos López",
    "creation_date": "2025-05-15",
    "status": "In Progress",
    "last_check": "2025-05-29",
    "comments": "Implementación de SonarQube completada, Checkmarx en progreso"
  },
  {
    "ticket": "CRQ000123471",
    "cis_control": 18,
    "project_action": "Pruebas de Penetración",
    "summary": "Realizar pruebas de penetración anuales",
    "description": "Contratar servicios de pruebas de penetración anuales para sistemas críticos y aplicaciones web",
    "risk": "Vulnerabilidades no detectadas",
    "impact": "Explotación de vulnerabilidades",
    "raw_probability": 65,
    "raw_impact": 90,
    "raw_risk": 59,
    "avoid": 0,
    "mitigate": 40,
    "transfer": 10,
    "accept": null,
    "treatment": "Contratar servicios de pentesting con firma especializada y establecer proceso de remediación",
    "treated_probability": 25,
    "treated_impact": 75,
    "current_risk": 19,
    "next_review": "2025-09-15",
    "department": "Seguridad",
    "owner": "Carlos López",
    "coordinator": "Ana Martínez",
    "technician": "Miguel Torres",
    "creation_date": "2025-05-16",
    "status": "Scheduled",
    "last_check": "2025-05-30",
    "comments": "Pentesting programado para julio 2025"
  },
  {
    "ticket": "CRQ000123472",
    "cis_control": 13,
    "project_action": "Capacitación",
    "summary": "Implementar programa de concientización",
    "description": "Implementar programa continuo de concientización en seguridad para todos los empleados",
    "risk": "Error humano",
    "impact": "Compromiso de sistemas por phishing o ingeniería social",
    "raw_probability": 90,
    "raw_impact": 80,
    "raw_risk": 72,
    "avoid": 0,
    "mitigate": 60,
    "transfer": 0,
    "accept": null,
    "treatment": "Implementar plataforma de capacitación KnowBe4 con simulaciones de phishing y módulos de aprendizaje",
    "treated_probability": 40,
    "treated_impact": 70,
    "current_risk": 28,
    "next_review": "2025-07-25",
    "department": "Seguridad",
    "owner": "Juan Pérez",
    "coordinator": "Laura García",
    "technician": "Sofia Hernández",
    "creation_date": "2025-05-17",
    "status": "Implementation In Progress",
    "last_check": "2025-05-31",
    "comments": "Plataforma implementada, creando contenido personalizado"
  },
  {
    "ticket": "CRQ000123473",
    "cis_control": 15,
    "project_action": "Gestión de Proveedores",
    "summary": "Implementar programa de gestión de riesgos de terceros",
    "description": "Establecer un programa formal de evaluación y gestión de riesgos de seguridad para proveedores",
    "risk": "Compromiso a través de terceros",
    "impact": "Acceso no autorizado a través de conexiones de terceros",
    "raw_probability": 75,
    "raw_impact": 85,
    "raw_risk": 64,
    "avoid": 0,
    "mitigate": 45,
    "transfer": 10,
    "accept": null,
    "treatment": "Implementar proceso de evaluación de seguridad para proveedores y monitoreo continuo",
    "treated_probability": 30,
    "treated_impact": 70,
    "current_risk": 21,
    "next_review": "2025-08-05",
    "department": "Seguridad",
    "owner": "María García",
    "coordinator": "Pedro Rodríguez",
    "technician": "Carlos López",
    "creation_date": "2025-05-18",
    "status": "Pending",
    "last_check": "2025-06-01",
    "comments": "Pendiente de asignación de recursos"
  },
  {
    "ticket": "CRQ000123474",
    "cis_control": 2,
    "project_action": "Inventario de Software",
    "summary": "Implementar gestión de activos de software",
    "description": "Implementar solución para inventario y gestión del ciclo de vida de software",
    "risk": "Software no autorizado o sin soporte",
    "impact": "Vulnerabilidades y problemas de cumplimiento",
    "raw_probability": 80,
    "raw_impact": 70,
    "raw_risk": 56,
    "avoid": 0,
    "mitigate": 40,
    "transfer": 0,
    "accept": null,
    "treatment": "Implementar Microsoft Endpoint Configuration Manager para inventario y gestión de software",
    "treated_probability": 30,
    "treated_impact": 60,
    "current_risk": 18,
    "next_review": "2025-07-15",
    "department": "Infraestructura",
    "owner": "Carlos López",
    "coordinator": "Ana Martínez",
    "technician": "Miguel Torres",
    "creation_date": "2025-05-19",
    "status": "Pending Ticket",
    "last_check": "2025-06-02",
    "comments": "Esperando creación del ticket en el sistema"
  },
  {
    "ticket": "CRQ000123475",
    "cis_control": 19,
    "project_action": "Compliance",
    "summary": "Implementar gestión de cumplimiento normativo",
    "description": "Implementar solución para gestión centralizada de cumplimiento normativo (GDPR, PCI-DSS, ISO 27001)",
    "risk": "Incumplimiento regulatorio",
    "impact": "Sanciones y pérdida de reputación",
    "raw_probability": 70,
    "raw_impact": 95,
    "raw_risk": 67,
    "avoid": 0,
    "mitigate": 50,
    "transfer": 10,
    "accept": null,
    "treatment": "Implementar plataforma GRC (Governance, Risk & Compliance) para gestión centralizada",
    "treated_probability": 20,
    "treated_impact": 90,
    "current_risk": 18,
    "next_review": "2025-09-10",
    "department": "Seguridad",
    "owner": "Juan Pérez",
    "coordinator": "Laura García",
    "technician": "Sofia Hernández",
    "creation_date": "2025-05-20",
    "status": "Request for Authorization",
    "last_check": "2025-06-03",
    "comments": "Esperando aprobación del presupuesto"
  }
]
[V0_FILE]shellscript:file="backend/alembic/env.py" isMerged="true"
from logging.config import fileConfig
from sqlalchemy import engine_from_config
from sqlalchemy import pool
from alembic import context
import os
import sys
from pathlib import Path

# Add parent directory to path
sys.path.append(str(Path(__file__).parent.parent))

from app.database import Base
from app.models import Task, Personnel

# this is the Alembic Config object, which provides
# access to the values within the .ini file in use.
config = context.config

# Interpret the config file for Python logging.
# This line sets up loggers basically.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# add your model's MetaData object here
# for 'autogenerate' support
target_metadata = Base.metadata

# other values from the config, defined by the needs of env.py,
# can be acquired:
# my_important_option = config.get_main_option("my_important_option")
# ... etc.

def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    # Get database URL from environment variable if available
    database_url = os.getenv("DATABASE_URL")
    if database_url:
        configuration = config.get_section(config.config_ini_section)
        configuration["sqlalchemy.url"] = database_url
        connectable = engine_from_config(
            configuration,
            prefix="sqlalchemy.",
            poolclass=pool.NullPool,
        )
    else:
        connectable = engine_from_config(
            config.get_section(config.config_ini_section),
            prefix="sqlalchemy.",
            poolclass=pool.NullPool,
        )

    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata
        )

        with context.begin_transaction():
            context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
[V0_FILE]shellscript:file="backend/alembic/script.py.mako" isMerged="true"
"""${message}

Revision ID: ${up_revision}
Revises: ${down_revision | comma,n}
Create Date: ${create_date}

"""
from alembic import op
import sqlalchemy as sa
${imports if imports else ""}

# revision identifiers, used by Alembic.
revision = ${repr(up_revision)}
down_revision = ${repr(down_revision)}
branch_labels = ${repr(branch_labels)}
depends_on = ${repr(depends_on)}


def upgrade() -> None:
    ${upgrades if upgrades else "pass"}


def downgrade() -> None:
    ${downgrades if downgrades else "pass"}
[V0_FILE]typescript:file="app/api/tasks/route.ts" isEdit="true" isMerged="true"
import { type NextRequest, NextResponse } from "next/server"
import { sql } from "@/lib/db"
import type { Task } from "@/lib/types"

export async function GET() {
  try {
    // Get all tasks
    const tasks = await sql<Task[]>`
      SELECT * FROM tasks 
      ORDER BY created_at DESC
    `

    // Separate tasks by status
    const inProgressTasks = tasks.filter((task) => !task.status.startsWith("Completed") && task.status !== "Closed")
    const closedTasks = tasks.filter((task) => task.status.startsWith("Completed") || task.status === "Closed")

    return NextResponse.json({
      inProgress: inProgressTasks,
      closed: closedTasks,
      all: tasks,
    })
  } catch (error) {
    console.error("Error fetching tasks:", error)
    return NextResponse.json({ error: "Failed to fetch tasks" }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    const taskData = await request.json()

    // Generate unique ID
    const id = `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`

    // Calculate risks
    const raw_risk = Math.round((taskData.raw_probability / 100) * (taskData.raw_impact / 100) * 100)
    const current_risk = Math.round((taskData.treated_probability / 100) * (taskData.treated_impact / 100) * 100)

    // Set dates
    const creation_date = taskData.creation_date || new Date().toISOString().split("T")[0]
    const last_check = taskData.last_check || new Date().toISOString().split("T")[0]
    const completion_date =
      taskData.status?.startsWith("Completed") || taskData.status === "Closed"
        ? taskData.completion_date || new Date().toISOString().split("T")[0]
        : null

    const task = await sql<Task[]>`
      INSERT INTO tasks (
        id, ticket, cis_control, project_action, summary, description,
        risk, impact, raw_probability, raw_impact, raw_risk,
        avoid, mitigate, transfer, accept, treatment,
        treated_probability, treated_impact, current_risk,
        next_review, department, owner, coordinator, technician,
        creation_date, status, last_check, comments, completion_date
      ) VALUES (
        ${id}, ${taskData.ticket || null}, ${taskData.cis_control}, ${taskData.project_action}, 
        ${taskData.summary}, ${taskData.description}, ${taskData.risk}, ${taskData.impact}, 
        ${taskData.raw_probability}, ${taskData.raw_impact}, ${raw_risk},
        ${taskData.avoid || 0}, ${taskData.mitigate || 0}, ${taskData.transfer || 0}, 
        ${taskData.accept || null}, ${taskData.treatment},
        ${taskData.treated_probability}, ${taskData.treated_impact}, ${current_risk},
        ${taskData.next_review}, ${taskData.department}, ${taskData.owner}, 
        ${taskData.coordinator}, ${taskData.technician},
        ${creation_date}, ${taskData.status}, ${last_check}, 
        ${taskData.comments}, ${completion_date}
      )
      RETURNING *
    `

    return NextResponse.json(task[0])
  } catch (error) {
    console.error("Error creating task:", error)
    return NextResponse.json({ error: "Failed to create task" }, { status: 500 })
  }
}
[V0_FILE]typescript:file="app/api/tasks/[id]/route.ts" isEdit="true" isMerged="true"
import { type NextRequest, NextResponse } from "next/server"
import { sql } from "@/lib/db"
import type { Task } from "@/lib/types"

export async function PUT(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const taskData = await request.json()

    // Calculate risks
    const raw_risk = Math.round((taskData.raw_probability / 100) * (taskData.raw_impact / 100) * 100)
    const current_risk = Math.round((taskData.treated_probability / 100) * (taskData.treated_impact / 100) * 100)

    // Update dates
    const last_check = new Date().toISOString().split("T")[0]
    const completion_date =
      taskData.status?.startsWith("Completed") || taskData.status === "Closed"
        ? taskData.completion_date || new Date().toISOString().split("T")[0]
        : taskData.completion_date || null

    const updatedTask = await sql<Task[]>`
      UPDATE tasks SET
        ticket = ${taskData.ticket || null},
        cis_control = ${taskData.cis_control},
        project_action = ${taskData.project_action},
        summary = ${taskData.summary},
        description = ${taskData.description},
        risk = ${taskData.risk},
        impact = ${taskData.impact},
        raw_probability = ${taskData.raw_probability},
        raw_impact = ${taskData.raw_impact},
        raw_risk = ${raw_risk},
        avoid = ${taskData.avoid || 0},
        mitigate = ${taskData.mitigate || 0},
        transfer = ${taskData.transfer || 0},
        accept = ${taskData.accept || null},
        treatment = ${taskData.treatment},
        treated_probability = ${taskData.treated_probability},
        treated_impact = ${taskData.treated_impact},
        current_risk = ${current_risk},
        next_review = ${taskData.next_review},
        department = ${taskData.department},
        owner = ${taskData.owner},
        coordinator = ${taskData.coordinator},
        technician = ${taskData.technician},
        status = ${taskData.status},
        last_check = ${last_check},
        comments = ${taskData.comments},
        completion_date = ${completion_date},
        updated_at = CURRENT_TIMESTAMP
      WHERE id = ${params.id}
      RETURNING *
    `

    if (updatedTask.length === 0) {
      return NextResponse.json({ error: "Task not found" }, { status: 404 })
    }

    return NextResponse.json(updatedTask[0])
  } catch (error) {
    console.error("Error updating task:", error)
    return NextResponse.json({ error: "Failed to update task" }, { status: 500 })
  }
}

export async function DELETE(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const result = await sql`
      DELETE FROM tasks WHERE id = ${params.id}
      RETURNING id
    `

    if (result.length === 0) {
      return NextResponse.json({ error: "Task not found" }, { status: 404 })
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error("Error deleting task:", error)
    return NextResponse.json({ error: "Failed to delete task" }, { status: 500 })
  }
}
[V0_FILE]typescript:file="app/api/tasks/export/route.ts" isEdit="true" isMerged="true"
import { type NextRequest, NextResponse } from "next/server"
import { sql } from "@/lib/db"
import { exportToCSV } from "@/lib/utils"

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const format = searchParams.get("format") || "json"

    const tasks = await sql`
      SELECT * FROM tasks 
      ORDER BY created_at DESC
    `

    if (format === "csv") {
      const csvContent = exportToCSV(tasks)
      return new NextResponse(csvContent, {
        headers: {
          "Content-Type": "text/csv",
          "Content-Disposition": 'attachment; filename="cybersec_tasks.csv"',
        },
      })
    }

    return new NextResponse(JSON.stringify(tasks, null, 2), {
      headers: {
        "Content-Type": "application/json",
        "Content-Disposition": 'attachment; filename="cybersec_tasks.json"',
      },
    })
  } catch (error) {
    console.error("Error exporting tasks:", error)
    return NextResponse.json({ error: "Failed to export tasks" }, { status: 500 })
  }
}
[V0_FILE]typescriptreact:file="app/api/init/route.ts" isEdit="true" isQuickEdit="true" isMerged="true"
import { NextResponse } from "next/server"
import { sql } from "@/lib/db"

const exampleTasks = [
  {
    ticket: "CRQ000123456",
    cis_control: 1,
    project_action: "Inventario de Activos",
    summary: "Actualizar inventario de servidores",
    description:
      "Realizar un inventario completo de todos los servidores físicos y virtuales en el datacenter principal",
    risk: "Activos no gestionados",
    impact: "Posibles vulnerabilidades no detectadas",
    raw_probability: 70,
    raw_impact: 80,
    raw_risk: 56,
    avoid: 0,
    mitigate: 40,
    transfer: 0,
    accept: null,
    treatment: "Implementar herramienta automatizada de descubrimiento de activos",
    treated_probability: 30,
    treated_impact: 60,
    current_risk: 18,
    next_review: "2025-08-15",
    department: "Infraestructura",
    owner: "Juan Pérez",
    coordinator: "Laura García",
    technician: "Carlos López",
    creation_date: "2025-05-01",
    status: "In Progress",
    last_check: "2025-05-15",
    comments: "Se ha completado el 60% del inventario",
  },
  {
    ticket: "CRQ000123457",
    cis_control: 3,
    project_action: "Protección de Datos",
    summary: "Implementar cifrado de datos en reposo",
    description: "Implementar cifrado para todos los datos sensibles almacenados en bases de datos corporativas",
    risk: "Exposición de datos sensibles",
    impact: "Violación de privacidad y posibles sanciones",
    raw_probability: 60,
    raw_impact: 90,
    raw_risk: 54,
    avoid: 0,
    mitigate: 30,
    transfer: 10,
    accept: null,
    treatment: "Implementar solución de cifrado transparente para bases de datos",
    treated_probability: 20,
    treated_impact: 70,
    current_risk: 14,
    next_review: "2025-07-20",
    department: "Seguridad",
    owner: "María García",
    coordinator: "Pedro Rodríguez",
    technician: "Sofia Hernández",
    creation_date: "2025-05-02",
    status: "Scheduled",
    last_check: "2025-05-16",
    comments: "Programado para implementación el 15/06/2025",
  },
  {
    ticket: "CRQ000123458",
    cis_control: 7,
    project_action: "Gestión de Vulnerabilidades",
    summary: "Implementar escaneo continuo de vulnerabilidades",
    description: "Configurar escaneos automáticos semanales de vulnerabilidades en todos los sistemas críticos",
    risk: "Vulnerabilidades no detectadas",
    impact: "Posible explotación de vulnerabilidades",
    raw_probability: 80,
    raw_impact: 85,
    raw_risk: 68,
    avoid: 0,
    mitigate: 50,
    transfer: 0,
    accept: null,
    treatment: "Implementar Qualys para escaneo continuo y automatizar la generación de tickets para remediación",
    treated_probability: 30,
    treated_impact: 70,
    current_risk: 21,
    next_review: "2025-06-30",
    department: "Seguridad",
    owner: "Carlos López",
    coordinator: "Ana Martínez",
    technician: "Miguel Torres",
    creation_date: "2025-05-03",
    status: "Implementation In Progress",
    last_check: "2025-05-17",
    comments: "Fase 1 completada, configurando escaneos automáticos",
  },
  {
    ticket: "CRQ000123459",
    cis_control: 10,
    project_action: "Defensa contra Malware",
    summary: "Actualizar solución antimalware",
    description:
      "Actualizar la solución antimalware corporativa a la última versión y asegurar cobertura en todos los endpoints",
    risk: "Infección por malware",
    impact: "Pérdida de datos, interrupción de servicios",
    raw_probability: 75,
    raw_impact: 80,
    raw_risk: 60,
    avoid: 0,
    mitigate: 45,
    transfer: 0,
    accept: null,
    treatment: "Actualizar a la versión más reciente y verificar la cobertura en todos los endpoints",
    treated_probability: 25,
    treated_impact: 60,
    current_risk: 15,
    next_review: "2025-07-15",
    department: "Operaciones",
    owner: "Juan Pérez",
    coordinator: "Laura García",
    technician: "Carlos López",
    creation_date: "2025-05-04",
    status: "Request for Authorization",
    last_check: "2025-05-18",
    comments: "Esperando aprobación del presupuesto",
  },
  {
    ticket: "CRQ000123460",
    cis_control: 4,
    project_action: "Configuración Segura",
    summary: "Implementar gestión de configuración segura",
    description:
      "Desarrollar e implementar líneas base de configuración segura para todos los sistemas operativos utilizados",
    risk: "Configuraciones inseguras",
    impact: "Vulnerabilidades explotables",
    raw_probability: 85,
    raw_impact: 75,
    raw_risk: 64,
    avoid: 0,
    mitigate: 55,
    transfer: 0,
    accept: null,
    treatment: "Implementar CIS Benchmarks y automatizar verificación de cumplimiento",
    treated_probability: 30,
    treated_impact: 60,
    current_risk: 18,
    next_review: "2025-08-01",
    department: "Infraestructura",
    owner: "María García",
    coordinator: "Pedro Rodríguez",
    technician: "Miguel Torres",
    creation_date: "2025-05-05",
    status: "Pending",
    last_check: "2025-05-19",
    comments: "Pendiente de asignación de recursos",
  },
  {
    ticket: "CRQ000123461",
    cis_control: 6,
    project_action: "Gestión de Accesos",
    summary: "Implementar autenticación multifactor",
    description: "Implementar MFA para todos los accesos administrativos a sistemas críticos",
    risk: "Compromiso de credenciales",
    impact: "Acceso no autorizado a sistemas críticos",
    raw_probability: 70,
    raw_impact: 90,
    raw_risk: 63,
    avoid: 0,
    mitigate: 50,
    transfer: 0,
    accept: null,
    treatment: "Implementar solución MFA basada en tokens y biometría",
    treated_probability: 20,
    treated_impact: 80,
    current_risk: 16,
    next_review: "2025-06-15",
    department: "Seguridad",
    owner: "Carlos López",
    coordinator: "Ana Martínez",
    technician: "Sofia Hernández",
    creation_date: "2025-05-06",
    status: "Completed 2025",
    last_check: "2025-05-20",
    completion_date: "2025-05-20",
    comments: "Implementado con éxito en todos los sistemas críticos",
  },
  {
    ticket: "CRQ000123462",
    cis_control: 8,
    project_action: "Gestión de Logs",
    summary: "Centralizar logs de seguridad",
    description: "Implementar un SIEM para centralizar y correlacionar logs de seguridad de todos los sistemas",
    risk: "Detección tardía de incidentes",
    impact: "Mayor tiempo de respuesta ante incidentes",
    raw_probability: 65,
    raw_impact: 75,
    raw_risk: 49,
    avoid: 0,
    mitigate: 35,
    transfer: 0,
    accept: null,
    treatment: "Implementar Splunk Enterprise Security y configurar reglas de correlación",
    treated_probability: 25,
    treated_impact: 60,
    current_risk: 15,
    next_review: "2025-07-30",
    department: "Operaciones",
    owner: "María García",
    coordinator: "Laura García",
    technician: "Miguel Torres",
    creation_date: "2025-05-07",
    status: "Completed 2024",
    last_check: "2024-12-15",
    completion_date: "2024-12-15",
    comments: "Implementado en diciembre 2024, funcionando correctamente",
  },
  {
    ticket: "CRQ000123463",
    cis_control: 17,
    project_action: "Gestión de Incidentes",
    summary: "Actualizar plan de respuesta a incidentes",
    description: "Revisar y actualizar el plan de respuesta a incidentes de seguridad",
    risk: "Respuesta ineficiente a incidentes",
    impact: "Mayor impacto de los incidentes",
    raw_probability: 60,
    raw_impact: 85,
    raw_risk: 51,
    avoid: 0,
    mitigate: 30,
    transfer: 10,
    accept: null,
    treatment: "Actualizar procedimientos, realizar simulacros y capacitar al personal",
    treated_probability: 30,
    treated_impact: 70,
    current_risk: 21,
    next_review: "2025-09-01",
    department: "Seguridad",
    owner: "Juan Pérez",
    coordinator: "Pedro Rodríguez",
    technician: "Carlos López",
    creation_date: "2025-05-08",
    status: "In Progress",
    last_check: "2025-05-22",
    comments: "Revisión en curso, 40% completado",
  },
  {
    ticket: "CRQ000123464",
    cis_control: 12,
    project_action: "Gestión de Red",
    summary: "Segmentar red corporativa",
    description: "Implementar segmentación de red basada en roles y funciones de negocio",
    risk: "Movimiento lateral en caso de compromiso",
    impact: "Propagación de amenazas en la red",
    raw_probability: 75,
    raw_impact: 85,
    raw_risk: 64,
    avoid: 0,
    mitigate: 45,
    transfer: 0,
    accept: null,
    treatment: "Implementar VLANs y firewalls internos para segmentar la red",
    treated_probability: 30,
    treated_impact: 70,
    current_risk: 21,
    next_review: "2025-08-15",
    department: "Infraestructura",
    owner: "Carlos López",
    coordinator: "Ana Martínez",
    technician: "Miguel Torres",
    creation_date: "2025-05-09",
    status: "Pending Ticket",
    last_check: "2025-05-23",
    comments: "Esperando creación del ticket en el sistema",
  },
  {
    ticket: "CRQ000123465",
    cis_control: 19,
    project_action: "Compliance",
    summary: "Auditoría de cumplimiento PCI-DSS",
    description: "Realizar auditoría interna de cumplimiento PCI-DSS antes de la certificación oficial",
    risk: "Incumplimiento regulatorio",
    impact: "Sanciones económicas y pérdida de reputación",
    raw_probability: 55,
    raw_impact: 95,
    raw_risk: 52,
    avoid: 0,
    mitigate: 35,
    transfer: 10,
    accept: null,
    treatment: "Contratar consultoría especializada para pre-auditoría y remediar hallazgos",
    treated_probability: 20,
    treated_impact: 90,
    current_risk: 18,
    next_review: "2025-06-30",
    department: "Seguridad",
    owner: "María García",
    coordinator: "Pedro Rodríguez",
    technician: "Sofia Hernández",
    creation_date: "2025-05-10",
    status: "Scheduled",
    last_check: "2025-05-24",
    comments: "Auditoría programada para el 15/07/2025",
  },
  {
    ticket: "CRQ000123466",
    cis_control: 5,
    project_action: "Gestión de Cuentas",
    summary: "Implementar revisión periódica de privilegios",
    description:
      "Establecer un proceso trimestral de revisión de privilegios para todas las cuentas con acceso a sistemas críticos",
    risk: "Acumulación de privilegios",
    impact: "Acceso excesivo a sistemas críticos",
    raw_probability: 80,
    raw_impact: 70,
    raw_risk: 56,
    avoid: 0,
    mitigate: 40,
    transfer: 0,
    accept: null,
    treatment: "Implementar herramienta de gestión de identidades y accesos (IAM) con workflows de aprobación",
    treated_probability: 30,
    treated_impact: 50,
    current_risk: 15,
    next_review: "2025-07-10",
    department: "Seguridad",
    owner: "Juan Pérez",
    coordinator: "Laura García",
    technician: "Sofia Hernández",
    creation_date: "2025-05-11",
    status: "Implementation In Progress",
    last_check: "2025-05-25",
    comments: "Fase de implementación de la herramienta IAM en curso",
  },
  {
    ticket: "CRQ000123467",
    cis_control: 14,
    project_action: "SOC",
    summary: "Implementar monitoreo 24/7",
    description:
      "Establecer un Centro de Operaciones de Seguridad (SOC) con monitoreo 24/7 para detección temprana de incidentes",
    risk: "Detección tardía de incidentes",
    impact: "Mayor tiempo de respuesta y potencial impacto",
    raw_probability: 75,
    raw_impact: 90,
    raw_risk: 68,
    avoid: 0,
    mitigate: 50,
    transfer: 10,
    accept: null,
    treatment: "Contratar servicio de SOC gestionado con SLAs de respuesta",
    treated_probability: 25,
    treated_impact: 70,
    current_risk: 18,
    next_review: "2025-08-20",
    department: "Seguridad",
    owner: "María García",
    coordinator: "Pedro Rodríguez",
    technician: "Carlos López",
    creation_date: "2025-05-12",
    status: "Request for Authorization",
    last_check: "2025-05-26",
    comments: "Esperando aprobación del presupuesto para el servicio de SOC",
  },
  {
    ticket: "CRQ000123468",
    cis_control: 11,
    project_action: "Recuperación de Datos",
    summary: "Implementar solución de backup en la nube",
    description: "Implementar solución de backup en la nube para datos críticos con capacidad de recuperación rápida",
    risk: "Pérdida de datos críticos",
    impact: "Interrupción de operaciones y pérdida financiera",
    raw_probability: 60,
    raw_impact: 95,
    raw_risk: 57,
    avoid: 0,
    mitigate: 40,
    transfer: 10,
    accept: null,
    treatment:
      "Implementar solución de backup en la nube con replicación geográfica y pruebas de recuperación mensuales",
    treated_probability: 20,
    treated_impact: 80,
    current_risk: 16,
    next_review: "2025-06-25",
    department: "Infraestructura",
    owner: "Carlos López",
    coordinator: "Ana Martínez",
    technician: "Miguel Torres",
    creation_date: "2025-05-13",
    status: "Completed 2025",
    last_check: "2025-05-27",
    completion_date: "2025-05-27",
    comments: "Implementación completada y pruebas de recuperación exitosas",
  },
  {
    ticket: "CRQ000123469",
    cis_control: 9,
    project_action: "Protección de Navegadores",
    summary: "Implementar filtrado de contenido web",
    description: "Implementar solución de filtrado de contenido web para proteger contra sitios maliciosos y phishing",
    risk: "Infección por malware vía web",
    impact: "Compromiso de sistemas y datos",
    raw_probability: 85,
    raw_impact: 75,
    raw_risk: 64,
    avoid: 0,
    mitigate: 50,
    transfer: 0,
    accept: null,
    treatment: "Implementar Cisco Umbrella para filtrado DNS y protección contra amenazas web",
    treated_probability: 30,
    treated_impact: 60,
    current_risk: 18,
    next_review: "2025-07-05",
    department: "Seguridad",
    owner: "Juan Pérez",
    coordinator: "Laura García",
    technician: "Sofia Hernández",
    creation_date: "2025-05-14",
    status: "Completed 2024",
    last_check: "2024-11-20",
    completion_date: "2024-11-20",
    comments: "Implementado en noviembre 2024, funcionando correctamente",
  },
  {
    ticket: "CRQ000123470",
    cis_control: 16,
    project_action: "Seguridad de Aplicaciones",
    summary: "Implementar análisis estático de código",
    description:
      "Implementar análisis estático de código (SAST) en el pipeline de CI/CD para detectar vulnerabilidades tempranamente",
    risk: "Vulnerabilidades en aplicaciones",
    impact: "Explotación de vulnerabilidades en producción",
    raw_probability: 70,
    raw_impact: 85,
    raw_risk: 60,
    avoid: 0,
    mitigate: 45,
    transfer: 0,
    accept: null,
    treatment: "Implementar SonarQube y Checkmarx en el pipeline de CI/CD",
    treated_probability: 25,
    treated_impact: 70,
    current_risk: 18,
    next_review: "2025-08-10",
    department: "Operaciones",
    owner: "María García",
    coordinator: "Pedro Rodríguez",
    technician: "Carlos López",
    creation_date: "2025-05-15",
    status: "In Progress",
    last_check: "2025-05-29",
    comments: "Implementación de SonarQube completada, Checkmarx en progreso",
  },
  {
    ticket: "CRQ000123471",
    cis_control: 18,
    project_action: "Pruebas de Penetración",
    summary: "Realizar pruebas de penetración anuales",
    description: "Contratar servicios de pruebas de penetración anuales para sistemas críticos y aplicaciones web",
    risk: "Vulnerabilidades no detectadas",
    impact: "Explotación de vulnerabilidades",
    raw_probability: 65,
    raw_impact: 90,
    raw_risk: 59,
    avoid: 0,
    mitigate: 40,
    transfer: 10,
    accept: null,
    treatment: "Contratar servicios de pentesting con firma especializada y establecer proceso de remediación",
    treated_probability: 25,
    treated_impact: 75,
    current_risk: 19,
    next_review: "2025-09-15",
    department: "Seguridad",
    owner: "Carlos López",
    coordinator: "Ana Martínez",
    technician: "Miguel Torres",
    creation_date: "2025-05-16",
    status: "Scheduled",
    last_check: "2025-05-30",
    comments: "Pentesting programado para julio 2025",
  },
  {
    ticket: "CRQ000123472",
    cis_control: 13,
    project_action: "Capacitación",
    summary: "Implementar programa de concientización",
    description: "Implementar programa continuo de concientización en seguridad para todos los empleados",
    risk: "Error humano",
    impact: "Compromiso de sistemas por phishing o ingeniería social",
    raw_probability: 90,
    raw_impact: 80,
    raw_risk: 72,
    avoid: 0,
    mitigate: 60,
    transfer: 0,
    accept: null,
    treatment: "Implementar plataforma de capacitación KnowBe4 con simulaciones de phishing y módulos de aprendizaje",
    treated_probability: 40,
    treated_impact: 70,
    current_risk: 28,
    next_review: "2025-07-25",
    department: "Seguridad",
    owner: "Juan Pérez",
    coordinator: "Laura García",
    technician: "Sofia Hernández",
    creation_date: "2025-05-17",
    status: "Implementation In Progress",
    last_check: "2025-05-31",
    comments: "Plataforma implementada, creando contenido personalizado",
  },
  {
    ticket: "CRQ000123473",
    cis_control: 15,
    project_action: "Gestión de Proveedores",
    summary: "Implementar programa de gestión de riesgos de terceros",
    description: "Establecer un programa formal de evaluación y gestión de riesgos de seguridad para proveedores",
    risk: "Compromiso a través de terceros",
    impact: "Acceso no autorizado a través de conexiones de terceros",
    raw_probability: 75,
    raw_impact: 85,
    raw_risk: 64,
    avoid: 0,
    mitigate: 45,
    transfer: 10,
    accept: null,
    treatment: "Implementar proceso de evaluación de seguridad para proveedores y monitoreo continuo",
    treated_probability: 30,
    treated_impact: 70,
    current_risk: 21,
    next_review: "2025-08-05",
    department: "Seguridad",
    owner: "María García",
    coordinator: "Pedro Rodríguez",
    technician: "Carlos López",
    creation_date: "2025-05-18",
    status: "Pending",
    last_check: "2025-06-01",
    comments: "Pendiente de asignación de recursos",
  },
  {
    ticket: "CRQ000123474",
    cis_control: 2,
    project_action: "Inventario de Software",
    summary: "Implementar gestión de activos de software",
    description: "Implementar solución para inventario y gestión del ciclo de vida de software",
    risk: "Software no autorizado o sin soporte",
    impact: "Vulnerabilidades y problemas de cumplimiento",
    raw_probability: 80,
    raw_impact: 70,
    raw_risk: 56,
    avoid: 0,
    mitigate: 40,
    transfer: 0,
    accept: null,
    treatment: "Implementar Microsoft Endpoint Configuration Manager para inventario y gestión de software",
    treated_probability: 30,
    treated_impact: 60,
    current_risk: 18,
    next_review: "2025-07-15",
    department: "Infraestructura",
    owner: "Carlos López",
    coordinator: "Ana Martínez",
    technician: "Miguel Torres",
    creation_date: "2025-05-19",
    status: "Pending Ticket",
    last_check: "2025-06-02",
    comments: "Esperando creación del ticket en el sistema",
  },
  {
    ticket: "CRQ000123475",
    cis_control: 19,
    project_action: "Compliance",
    summary: "Implementar gestión de cumplimiento normativo",
    description: "Implementar solución para gestión centralizada de cumplimiento normativo (GDPR, PCI-DSS, ISO 27001)",
    risk: "Incumplimiento regulatorio",
    impact: "Sanciones y pérdida de reputación",
    raw_probability: 70,
    raw_impact: 95,
    raw_risk: 67,
    avoid: 0,
    mitigate: 50,
    transfer: 10,
    accept: null,
    treatment: "Implementar plataforma GRC (Governance, Risk & Compliance) para gestión centralizada",
    treated_probability: 20,
    treated_impact: 90,
    current_risk: 18,
    next_review: "2025-09-10",
    department: "Seguridad",
    owner: "Juan Pérez",
    coordinator: "Laura García",
    technician: "Sofia Hernández",
    creation_date: "2025-05-20",
    status: "Request for Authorization",
    last_check: "2025-06-03",
    comments: "Esperando aprobación del presupuesto",
  },
]

const defaultPersonnel = [
  { name: "Juan Pérez", type: "owners" },
  { name: "María García", type: "owners" },
  { name: "Carlos López", type: "owners" },
  { name: "Laura García", type: "coordinators" },
  { name: "Ana Martínez", type: "coordinators" },
  { name: "Pedro Rodríguez", type: "coordinators" },
  { name: "Carlos López", type: "technicians" },
  { name: "Miguel Torres", type: "technicians" },
  { name: "Sofia Hernández", type: "technicians" },
]

export async function GET() {
  try {
    // Create tables one by one
    // Create personnel table if it doesn't exist
    await sql`
      CREATE TABLE IF NOT EXISTS personnel (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        type VARCHAR(50) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `

    // Create tasks table if it doesn't exist
    await sql`
      CREATE TABLE IF NOT EXISTS tasks (
        id VARCHAR(255) PRIMARY KEY,
        ticket VARCHAR(255),
        cis_control INTEGER NOT NULL,
        project_action VARCHAR(255) NOT NULL,
        summary VARCHAR(255) NOT NULL,
        description TEXT NOT NULL,
        risk VARCHAR(255),
        impact VARCHAR(255),
        raw_probability FLOAT NOT NULL,
        raw_impact FLOAT NOT NULL,
        raw_risk FLOAT NOT NULL,
        avoid FLOAT DEFAULT 0,
        mitigate FLOAT DEFAULT 0,
        transfer FLOAT DEFAULT 0,
        accept FLOAT,
        treatment TEXT NOT NULL,
        treated_probability FLOAT NOT NULL,
        treated_impact FLOAT NOT NULL,
        current_risk FLOAT NOT NULL,
        next_review VARCHAR(255) NOT NULL,
        department VARCHAR(255) NOT NULL,
        owner VARCHAR(255) NOT NULL,
        coordinator VARCHAR(255) NOT NULL,
        technician VARCHAR(255) NOT NULL,
        creation_date VARCHAR(255) NOT NULL,
        status VARCHAR(255) NOT NULL,
        last_check VARCHAR(255) NOT NULL,
        comments TEXT,
        completion_date VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `

    // Create task_owners association table if it doesn't exist
    await sql`
      CREATE TABLE IF NOT EXISTS task_owners (
        task_id VARCHAR(255) REFERENCES tasks(id) ON DELETE CASCADE,
        personnel_id INTEGER REFERENCES personnel(id) ON DELETE CASCADE,
        PRIMARY KEY (task_id, personnel_id)
      )
    `

    // Create task_coordinators association table if it doesn't exist
    await sql`
      CREATE TABLE IF NOT EXISTS task_coordinators (
        task_id VARCHAR(255) REFERENCES tasks(id) ON DELETE CASCADE,
        personnel_id INTEGER REFERENCES personnel(id) ON DELETE CASCADE,
        PRIMARY KEY (task_id, personnel_id)
      )
    `

    // Create task_technicians association table if it doesn't exist
    await sql`
      CREATE TABLE IF NOT EXISTS task_technicians (
        task_id VARCHAR(255) REFERENCES tasks(id) ON DELETE CASCADE,
        personnel_id INTEGER REFERENCES personnel(id) ON DELETE CASCADE,
        PRIMARY KEY (task_id, personnel_id)
      )
    `

    // Check if tables exist and have data
    const taskCount = await sql`SELECT COUNT(*) FROM tasks`

    if (Number(taskCount[0].count) === 0) {
      // Insert example tasks
      for (const task of exampleTasks) {
        const id = `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
        await sql`
          INSERT INTO tasks (
            id, ticket, cis_control, project_action, summary, description,
            risk, impact, raw_probability, raw_impact, raw_risk,
            avoid, mitigate, transfer, accept, treatment,
            treated_probability, treated_impact, current_risk,
            next_review, department, owner, coordinator, technician,
            creation_date, status, last_check, comments, completion_date
          ) VALUES (
            ${id}, ${task.ticket}, ${task.cis_control}, ${task.project_action}, 
            ${task.summary}, ${task.description}, ${task.risk}, ${task.impact}, 
            ${task.raw_probability}, ${task.raw_impact}, ${task.raw_risk},
            ${task.avoid}, ${task.mitigate}, ${task.transfer}, 
            ${task.accept}, ${task.treatment},
            ${task.treated_probability}, ${task.treated_impact}, ${task.current_risk},
            ${task.next_review}, ${task.department}, ${task.owner}, 
            ${task.coordinator}, ${task.technician},
            ${task.creation_date}, ${task.status}, ${task.last_check}, 
            ${task.comments}, ${task.completion_date}
          )
        `
      }
    }

    // Check personnel
    const personnelCount = await sql`SELECT COUNT(*) FROM personnel`

    if (Number(personnelCount[0].count) === 0) {
      // Insert default personnel
      for (const person of defaultPersonnel) {
        await sql`
          INSERT INTO personnel (name, type)
          VALUES (${person.name}, ${person.type})
        `
      }
    }

    return NextResponse.json({
      success: true,
      message: "Database initialized successfully",
    })
  } catch (error) {
    console.error("Error initializing database:", error)
    return NextResponse.json(
      {
        error: "Failed to initialize database",
        details: error instanceof Error ? error.message : String(error),
      },
      { status: 500 },
    )
  }
}

export async function POST() {
  return GET()
}
[V0_FILE]plaintext:file=".env.local.example" isMerged="true"
# Database
DATABASE_URL=postgresql://cybersec_user:cybersec_password@localhost:5432/cybersec_tasks

# Application
NEXT_PUBLIC_APP_URL=http://localhost:3000
[V0_FILE]plaintext:file=".dockerignore" isMerged="true"
.git
.github
node_modules
.next
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
README.md
.dockerignore
Dockerfile
docker-compose.yml
[V0_FILE]typescriptreact:file="components/ui/checkbox.tsx" isMerged="true"
"use client"

import * as React from "react"
import * as CheckboxPrimitive from "@radix-ui/react-checkbox"
import { Check, Minus } from "lucide-react"

import { cn } from "@/lib/utils"

const Checkbox = React.forwardRef<
  React.ElementRef<typeof CheckboxPrimitive.Root>,
  React.ComponentPropsWithoutRef<typeof CheckboxPrimitive.Root> & {
    indeterminate?: boolean
  }
>(({ className, indeterminate, ...props }, ref) => {
  const checkboxRef = React.useRef<HTMLButtonElement>(null)

  React.useEffect(() => {
    if (checkboxRef.current && indeterminate !== undefined) {
      checkboxRef.current.dataset.state = indeterminate ? "indeterminate" : props.checked ? "checked" : "unchecked"
    }
  }, [indeterminate, props.checked])

  return (
    <CheckboxPrimitive.Root
      ref={(node) => {
        // Handle both the forwarded ref and our local ref
        if (typeof ref === "function") ref(node)
        else if (ref) ref.current = node
        checkboxRef.current = node
      }}
      className={cn(
        "peer h-4 w-4 shrink-0 rounded-sm border border-primary ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 data-[state=checked]:bg-primary data-[state=checked]:text-primary-foreground data-[state=indeterminate]:bg-primary data-[state=indeterminate]:text-primary-foreground",
        className,
      )}
      {...props}
    >
      <CheckboxPrimitive.Indicator className={cn("flex items-center justify-center text-current")}>
        {indeterminate ? <Minus className="h-3 w-3" /> : <Check className="h-3 w-3" />}
      </CheckboxPrimitive.Indicator>
    </CheckboxPrimitive.Root>
  )
})
Checkbox.displayName = CheckboxPrimitive.Root.displayName

export { Checkbox }
[V0_FILE]typescriptreact:file="components/task-kanban.tsx" isEdit="true" isMerged="true"
"use client"

import type { Task, TaskStatus } from "@/lib/types"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { getRiskBadgeStyles, formatDate } from "@/lib/utils"
import { Edit, Trash2 } from "lucide-react"

interface TaskKanbanProps {
  tasks: Task[]
  onEditTask: (task: Task) => void
  onDeleteTask: (id: string) => void
}

// Filtrar las columnas para excluir las completadas
const statusColumns: TaskStatus[] = [
  "Pending Ticket",
  "Pending",
  "Scheduled",
  "Request for Authorization",
  "In Progress",
  "Implementation In Progress",
]

export function TaskKanban({ tasks, onEditTask, onDeleteTask }: TaskKanbanProps) {
  // Filtrar las tareas para excluir las completadas
  const activeTasks = tasks.filter((task) => !task.status.startsWith("Completed") && task.status !== "Closed")

  const getTasksByStatus = (status: TaskStatus) => {
    return activeTasks.filter((task) => task.status === status)
  }

  return (
    <div className="flex gap-4 overflow-x-auto pb-4">
      {statusColumns.map((status) => {
        const statusTasks = getTasksByStatus(status)
        return (
          <div key={status} className="min-w-[300px] flex-shrink-0">
            <div className="bg-gray-100 rounded-lg p-4">
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-semibold text-sm">{status}</h3>
                <Badge variant="secondary">{statusTasks.length}</Badge>
              </div>
              <div className="space-y-3">
                {statusTasks.map((task) => (
                  <Card key={task.id} className="cursor-pointer hover:shadow-md transition-shadow">
                    <CardHeader className="pb-2">
                      <div className="flex items-start justify-between">
                        <CardTitle className="text-sm font-medium">{task.summary}</CardTitle>
                        <div className="flex gap-1">
                          <Button size="sm" variant="ghost" onClick={() => onEditTask(task)}>
                            <Edit className="w-3 h-3" />
                          </Button>
                          <Button size="sm" variant="ghost" onClick={() => onDeleteTask(task.id)}>
                            <Trash2 className="w-3 h-3" />
                          </Button>
                        </div>
                      </div>
                    </CardHeader>
                    <CardContent className="pt-0">
                      <div className="space-y-2">
                        <p className="text-xs text-gray-600">{task.ticket}</p>
                        <p className="text-xs">{task.project_action}</p>
                        <div className="flex items-center justify-between">
                          <Badge className={`text-xs ${getRiskBadgeStyles(task.current_risk)}`}>
                            Risk: {task.current_risk}%
                          </Badge>
                          <span className="text-xs text-gray-500">{task.owner}</span>
                        </div>
                        <p className="text-xs text-gray-500">Updated: {formatDate(task.last_check)}</p>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </div>
          </div>
        )
      })}
    </div>
  )
}
[V0_FILE]json:file="template-import.json" isMerged="true"
[
  {
    "ticket": "CRQ000123456",
    "cis_control": 1,
    "project_action": "Asset Inventory",
    "summary": "Update server inventory",
    "description": "Perform a complete inventory of all physical and virtual servers in the main datacenter",
    "risk": "Unmanaged assets",
    "impact": "Potential undetected vulnerabilities",
    "raw_probability": 70,
    "raw_impact": 80,
    "raw_risk": 56,
    "avoid": 0,
    "mitigate": 40,
    "transfer": 0,
    "accept": null,
    "treatment": "Implement automated asset discovery tool",
    "treated_probability": 30,
    "treated_impact": 60,
    "current_risk": 18,
    "next_review": "2025-08-15",
    "department": "Infrastructure",
    "owner": "John Smith",
    "coordinator": "Laura Johnson",
    "technician": "Carlos Rodriguez",
    "creation_date": "2025-05-01",
    "status": "In Progress",
    "last_check": "2025-05-15",
    "comments": "60% of inventory completed",
    "completion_date": null
  },
  {
    "ticket": "CRQ000123457",
    "cis_control": 3,
    "project_action": "Data Protection",
    "summary": "Implement data-at-rest encryption",
    "description": "Implement encryption for all sensitive data stored in corporate databases",
    "risk": "Exposure of sensitive data",
    "impact": "Privacy breach and potential penalties",
    "raw_probability": 60,
    "raw_impact": 90,
    "raw_risk": 54,
    "avoid": 0,
    "mitigate": 30,
    "transfer": 10,
    "accept": null,
    "treatment": "Implement transparent database encryption solution",
    "treated_probability": 20,
    "treated_impact": 70,
    "current_risk": 14,
    "next_review": "2025-07-20",
    "department": "Security",
    "owner": "Maria Garcia",
    "coordinator": "Peter Rodriguez",
    "technician": "Sofia Hernandez",
    "creation_date": "2025-05-02",
    "status": "Scheduled",
    "last_check": "2025-05-16",
    "comments": "Scheduled for implementation on 06/15/2025",
    "completion_date": null
  },
  {
    "ticket": "CRQ000123458",
    "cis_control": 7,
    "project_action": "Vulnerability Management",
    "summary": "Implement continuous vulnerability scanning",
    "description": "Configure weekly automated vulnerability scans for all critical systems",
    "risk": "Undetected vulnerabilities",
    "impact": "Potential exploitation of vulnerabilities",
    "raw_probability": 80,
    "raw_impact": 85,
    "raw_risk": 68,
    "avoid": 0,
    "mitigate": 50,
    "transfer": 0,
    "accept": null,
    "treatment": "Implement Qualys for continuous scanning and automate remediation ticket generation",
    "treated_probability": 30,
    "treated_impact": 70,
    "current_risk": 21,
    "next_review": "2025-06-30",
    "department": "Security",
    "owner": "Carlos Lopez",
    "coordinator": "Ana Martinez",
    "technician": "Miguel Torres",
    "creation_date": "2025-05-03",
    "status": "Implementation In Progress",
    "last_check": "2025-05-17",
    "comments": "Phase 1 completed, configuring automated scans",
    "completion_date": null
  },
  {
    "ticket": "CRQ000123461",
    "cis_control": 6,
    "project_action": "Access Management",
    "summary": "Implement multi-factor authentication",
    "description": "Implement MFA for all administrative access to critical systems",
    "risk": "Credential compromise",
    "impact": "Unauthorized access to critical systems",
    "raw_probability": 70,
    "raw_impact": 90,
    "raw_risk": 63,
    "avoid": 0,
    "mitigate": 50,
    "transfer": 0,
    "accept": null,
    "treatment": "Implement MFA solution based on tokens and biometrics",
    "treated_probability": 20,
    "treated_impact": 80,
    "current_risk": 16,
    "next_review": "2025-06-15",
    "department": "Security",
    "owner": "Carlos Lopez",
    "coordinator": "Ana Martinez",
    "technician": "Sofia Hernandez",
    "creation_date": "2025-05-06",
    "status": "Completed 2025",
    "last_check": "2025-05-20",
    "completion_date": "2025-05-20",
    "comments": "Successfully implemented on all critical systems"
  },
  {
    "ticket": "CRQ000123462",
    "cis_control": 8,
    "project_action": "Log Management",
    "summary": "Centralize security logs",
    "description": "Implement a SIEM to centralize and correlate security logs from all systems",
    "risk": "Delayed incident detection",
    "impact": "Increased incident response time",
    "raw_probability": 65,
    "raw_impact": 75,
    "raw_risk": 49,
    "avoid": 0,
    "mitigate": 35,
    "transfer": 0,
    "accept": null,
    "treatment": "Implement Splunk Enterprise Security and configure correlation rules",
    "treated_probability": 25,
    "treated_impact": 60,
    "current_risk": 15,
    "next_review": "2025-07-30",
    "department": "Operations",
    "owner": "Maria Garcia",
    "coordinator": "Laura Garcia",
    "technician": "Miguel Torres",
    "creation_date": "2025-05-07",
    "status": "Completed 2024",
    "last_check": "2024-12-15",
    "completion_date": "2024-12-15",
    "comments": "Implemented in December 2024, working correctly"
  }
]
[V0_FILE]markdown:file="import-format.md" isMerged="true"
# CyberSec Tasks - Import Format Guide

This document explains the format for importing tasks into the CyberSec Tasks application.

## Import Format

The import file must be a valid JSON file containing an array of task objects. Each task object must have the following structure:

\`\`\`json
{
  "ticket": "CRQ000123456",              // Optional: Ticket number or identifier
  "cis_control": 1,                      // Required: CIS Control number (1-19)
  "project_action": "Asset Inventory",   // Required: Project or action name
  "summary": "Update server inventory",  // Required: Brief summary of the task
  "description": "Perform a complete...", // Required: Detailed description
  "risk": "Unmanaged assets",            // Optional: Risk description
  "impact": "Potential undetected...",   // Optional: Impact description
  "raw_probability": 70,                 // Required: Raw probability (0-100)
  "raw_impact": 80,                      // Required: Raw impact (0-100)
  "raw_risk": 56,                        // Optional: Will be calculated if not provided
  "avoid": 0,                            // Optional: Avoid percentage (0-100)
  "mitigate": 40,                        // Optional: Mitigate percentage (0-100)
  "transfer": 0,                         // Optional: Transfer percentage (0-100)
  "accept": null,                        // Optional: Accept percentage (0-100 or null)
  "treatment": "Implement automated...", // Required: Treatment or task description
  "treated_probability": 30,             // Required: Treated probability (0-100)
  "treated_impact": 60,                  // Required: Treated impact (0-100)
  "current_risk": 18,                    // Optional: Will be calculated if not provided
  "next_review": "2025-08-15",           // Required: Next review date (YYYY-MM-DD)
  "department": "Infrastructure",        // Required: Department name
  "owner": "John Smith",                 // Required: Owner name
  "coordinator": "Laura Johnson",        // Required: Coordinator name
  "technician": "Carlos Rodriguez",      // Required: Technician name
  "creation_date": "2025-05-01",         // Optional: Creation date (YYYY-MM-DD)
  "status": "In Progress",               // Required: Status (see valid statuses below)
  "last_check": "2025-05-15",            // Optional: Last check date (YYYY-MM-DD)
  "comments": "60% of inventory...",     // Optional: Comments
  "completion_date": null                // Optional: Completion date for completed tasks
}
\`\`\`

## Valid Status Values

The following status values are valid:

- "Pending Ticket"
- "Pending"
- "Scheduled"
- "Request for Authorization"
- "In Progress"
- "Implementation In Progress"
- "Completed 2025"
- "Completed 2024"
- "Closed"

## Risk Calculation

If `raw_risk` or `current_risk` are not provided, they will be calculated automatically:

- `raw_risk` = (raw_probability / 100) * (raw_impact / 100) * 100
- `current_risk` = (treated_probability / 100) * (treated_impact / 100) * 100

## Dates Format

All dates must be in the format "YYYY-MM-DD" (e.g., "2025-05-15").

## Example Import File

See the `template-import.json` file for a complete example with multiple tasks.

## Import Process

1. Prepare your JSON file according to this format
2. In the application, click on "Import JSON"
3. Select your file
4. Review the tasks in the preview
5. Confirm the import

## Notes

- The `id` field is not required for import. New IDs will be generated automatically.
- If a task with the same ID already exists, it will be updated.
- Personnel (owners, coordinators, technicians) will be created automatically if they don't exist.
\`\`\`

Ahora, vamos a añadir un componente para mostrar la documentación de importación:
[V0_FILE]typescriptreact:file="components/import-help-dialog.tsx" isMerged="true"
"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { HelpCircle, FileJson, FileText } from "lucide-react"

export function ImportHelpDialog() {
  const [isOpen, setIsOpen] = useState(false)

  return (
    <>
      <Button variant="ghost" size="sm" onClick={() => setIsOpen(true)}>
        <HelpCircle className="h-4 w-4 mr-1" />
        Import Help
      </Button>

      <Dialog open={isOpen} onOpenChange={setIsOpen}>
        <DialogContent className="max-w-4xl max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Import Format Documentation</DialogTitle>
          </DialogHeader>

          <Tabs defaultValue="docs">
            <TabsList className="mb-4">
              <TabsTrigger value="docs">
                <FileText className="h-4 w-4 mr-2" />
                Documentation
              </TabsTrigger>
              <TabsTrigger value="template">
                <FileJson className="h-4 w-4 mr-2" />
                JSON Template
              </TabsTrigger>
            </TabsList>

            <TabsContent value="docs" className="prose prose-sm max-w-none">
              <h2>Import Format</h2>
              <p>
                The import file must be a valid JSON file containing an array of task objects. Each task object must
                have the following structure:
              </p>

              <pre className="bg-gray-100 p-4 rounded-md overflow-x-auto text-xs">
                {`{
  "ticket": "CRQ000123456",              // Optional: Ticket number or identifier
  "cis_control": 1,                      // Required: CIS Control number (1-19)
  "project_action": "Asset Inventory",   // Required: Project or action name
  "summary": "Update server inventory",  // Required: Brief summary of the task
  "description": "Perform a complete...", // Required: Detailed description
  "risk": "Unmanaged assets",            // Optional: Risk description
  "impact": "Potential undetected...",   // Optional: Impact description
  "raw_probability": 70,                 // Required: Raw probability (0-100)
  "raw_impact": 80,                      // Required: Raw impact (0-100)
  "raw_risk": 56,                        // Optional: Will be calculated if not provided
  "avoid": 0,                            // Optional: Avoid percentage (0-100)
  "mitigate": 40,                        // Optional: Mitigate percentage (0-100)
  "transfer": 0,                         // Optional: Transfer percentage (0-100)
  "accept": null,                        // Optional: Accept percentage (0-100 or null)
  "treatment": "Implement automated...", // Required: Treatment or task description
  "treated_probability": 30,             // Required: Treated probability (0-100)
  "treated_impact": 60,                  // Required: Treated impact (0-100)
  "current_risk": 18,                    // Optional: Will be calculated if not provided
  "next_review": "2025-08-15",           // Required: Next review date (YYYY-MM-DD)
  "department": "Infrastructure",        // Required: Department name
  "owner": "John Smith",                 // Required: Owner name
  "coordinator": "Laura Johnson",        // Required: Coordinator name
  "technician": "Carlos Rodriguez",      // Required: Technician name
  "creation_date": "2025-05-01",         // Optional: Creation date (YYYY-MM-DD)
  "status": "In Progress",               // Required: Status (see valid statuses below)
  "last_check": "2025-05-15",            // Optional: Last check date (YYYY-MM-DD)
  "comments": "60% of inventory...",     // Optional: Comments
  "completion_date": null                // Optional: Completion date for completed tasks
}`}
              </pre>

              <h2>Valid Status Values</h2>
              <p>The following status values are valid:</p>
              <ul>
                <li>"Pending Ticket"</li>
                <li>"Pending"</li>
                <li>"Scheduled"</li>
                <li>"Request for Authorization"</li>
                <li>"In Progress"</li>
                <li>"Implementation In Progress"</li>
                <li>"Completed 2025"</li>
                <li>"Completed 2024"</li>
                <li>"Closed"</li>
              </ul>

              <h2>Risk Calculation</h2>
              <p>
                If <code>raw_risk</code> or <code>current_risk</code> are not provided, they will be calculated
                automatically:
              </p>
              <ul>
                <li>
                  <code>raw_risk</code> = (raw_probability / 100) * (raw_impact / 100) * 100
                </li>
                <li>
                  <code>current_risk</code> = (treated_probability / 100) * (treated_impact / 100) * 100
                </li>
              </ul>

              <h2>Dates Format</h2>
              <p>All dates must be in the format "YYYY-MM-DD" (e.g., "2025-05-15").</p>

              <h2>Import Process</h2>
              <ol>
                <li>Prepare your JSON file according to this format</li>
                <li>In the application, click on "Import JSON"</li>
                <li>Select your file</li>
                <li>Review the tasks in the preview</li>
                <li>Confirm the import</li>
              </ol>

              <h2>Notes</h2>
              <ul>
                <li>
                  The <code>id</code> field is not required for import. New IDs will be generated automatically.
                </li>
                <li>If a task with the same ID already exists, it will be updated.</li>
                <li>
                  Personnel (owners, coordinators, technicians) will be created automatically if they don't exist.
                </li>
              </ul>
            </TabsContent>

            <TabsContent value="template">
              <div className="flex justify-between mb-4">
                <h3 className="text-lg font-medium">JSON Template</h3>
                <Button
                  size="sm"
                  onClick={() => {
                    // Create a blob with the template JSON
                    const templateJson = JSON.stringify(
                      [
                        {
                          ticket: "CRQ000123456",
                          cis_control: 1,
                          project_action: "Asset Inventory",
                          summary: "Update server inventory",
                          description:
                            "Perform a complete inventory of all physical and virtual servers in the main datacenter",
                          risk: "Unmanaged assets",
                          impact: "Potential undetected vulnerabilities",
                          raw_probability: 70,
                          raw_impact: 80,
                          raw_risk: 56,
                          avoid: 0,
                          mitigate: 40,
                          transfer: 0,
                          accept: null,
                          treatment: "Implement automated asset discovery tool",
                          treated_probability: 30,
                          treated_impact: 60,
                          current_risk: 18,
                          next_review: "2025-08-15",
                          department: "Infrastructure",
                          owner: "John Smith",
                          coordinator: "Laura Johnson",
                          technician: "Carlos Rodriguez",
                          creation_date: "2025-05-01",
                          status: "In Progress",
                          last_check: "2025-05-15",
                          comments: "60% of inventory completed",
                          completion_date: null,
                        },
                      ],
                      null,
                      2,
                    )
                    const blob = new Blob([templateJson], { type: "application/json" })
                    const url = URL.createObjectURL(blob)
                    const a = document.createElement("a")
                    a.href = url
                    a.download = "template-import.json"
                    a.click()
                    URL.revokeObjectURL(url)
                  }}
                >
                  Download Template
                </Button>
              </div>

              <div className="bg-gray-100 p-4 rounded-md overflow-x-auto text-xs">
                <pre>{`[
  {
    "ticket": "CRQ000123456",
    "cis_control": 1,
    "project_action": "Asset Inventory",
    "summary": "Update server inventory",
    "description": "Perform a complete inventory of all physical and virtual servers in the main datacenter",
    "risk": "Unmanaged assets",
    "impact": "Potential undetected vulnerabilities",
    "raw_probability": 70,
    "raw_impact": 80,
    "raw_risk": 56,
    "avoid": 0,
    "mitigate": 40,
    "transfer": 0,
    "accept": null,
    "treatment": "Implement automated asset discovery tool",
    "treated_probability": 30,
    "treated_impact": 60,
    "current_risk": 18,
    "next_review": "2025-08-15",
    "department": "Infrastructure",
    "owner": "John Smith",
    "coordinator": "Laura Johnson",
    "technician": "Carlos Rodriguez",
    "creation_date": "2025-05-01",
    "status": "In Progress",
    "last_check": "2025-05-15",
    "comments": "60% of inventory completed",
    "completion_date": null
  },
  {
    "ticket": "CRQ000123457",
    "cis_control": 3,
    "project_action": "Data Protection",
    "summary": "Implement data-at-rest encryption",
    "description": "Implement encryption for all sensitive data stored in corporate databases",
    "risk": "Exposure of sensitive data",
    "impact": "Privacy breach and potential penalties",
    "raw_probability": 60,
    "raw_impact": 90,
    "raw_risk": 54,
    "avoid": 0,
    "mitigate": 30,
    "transfer": 10,
    "accept": null,
    "treatment": "Implement transparent database encryption solution",
    "treated_probability": 20,
    "treated_impact": 70,
    "current_risk": 14,
    "next_review": "2025-07-20",
    "department": "Security",
    "owner": "Maria Garcia",
    "coordinator": "Peter Rodriguez",
    "technician": "Sofia Hernandez",
    "creation_date": "2025-05-02",
    "status": "Scheduled",
    "last_check": "2025-05-16",
    "comments": "Scheduled for implementation on 06/15/2025",
    "completion_date": null
  }
]`}</pre>
              </div>

              <div className="mt-4 text-sm text-gray-600">
                <p>
                  <strong>Note:</strong> This is a simplified template. You can add more tasks to the array as needed.
                  The template includes the minimum required fields for a successful import.
                </p>
              </div>
            </TabsContent>
          </Tabs>
        </DialogContent>
      </Dialog>
    </>
  )
}
[V0_FILE]typescriptreact:file="components/dashboard/dashboard-stats.tsx" isMerged="true"
"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import type { Task } from "@/lib/types"
import { getRiskLevel } from "@/lib/utils"
import { Shield, AlertTriangle, CheckCircle, Clock, TrendingUp, Users, Activity, Calendar } from "lucide-react"

interface DashboardStatsProps {
  tasks: Task[]
}

export function DashboardStats({ tasks }: DashboardStatsProps) {
  // Calcular estadísticas
  const totalTasks = tasks.length
  const completedTasks = tasks.filter((t) => t.status.startsWith("Completed") || t.status === "Closed").length
  const inProgressTasks = tasks.filter(
    (t) => t.status === "In Progress" || t.status === "Implementation In Progress",
  ).length
  const pendingTasks = tasks.filter((t) => t.status === "Pending" || t.status === "Pending Ticket").length
  const scheduledTasks = tasks.filter((t) => t.status === "Scheduled").length

  // Calcular porcentaje de completado
  const completionRate = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0

  // Calcular riesgos
  const criticalRiskTasks = tasks.filter((t) => getRiskLevel(t.current_risk) === "Critical").length
  const highRiskTasks = tasks.filter((t) => getRiskLevel(t.current_risk) === "High").length
  const mediumRiskTasks = tasks.filter(
    (t) => getRiskLevel(t.current_risk) === "Medium" || getRiskLevel(t.current_risk) === "Medium-High",
  ).length
  const lowRiskTasks = tasks.filter(
    (t) =>
      getRiskLevel(t.current_risk) === "Low" ||
      getRiskLevel(t.current_risk) === "Low-Medium" ||
      getRiskLevel(t.current_risk) === "Very Low" ||
      getRiskLevel(t.current_risk) === "Minimal",
  ).length

  // Calcular promedio de riesgo
  const averageRisk =
    tasks.length > 0 ? Math.round(tasks.reduce((sum, task) => sum + task.current_risk, 0) / tasks.length) : 0

  // Tareas que requieren revisión pronto (próximos 30 días)
  const today = new Date()
  const thirtyDaysFromNow = new Date(today.getTime() + 30 * 24 * 60 * 60 * 1000)
  const upcomingReviews = tasks.filter((t) => {
    if (t.next_review && t.next_review !== "N/A") {
      const reviewDate = new Date(t.next_review)
      return reviewDate >= today && reviewDate <= thirtyDaysFromNow
    }
    return false
  }).length

  const stats = [
    {
      title: "Total Tasks",
      value: totalTasks,
      icon: Shield,
      color: "text-blue-600",
      bgColor: "bg-blue-100",
    },
    {
      title: "Completed",
      value: completedTasks,
      icon: CheckCircle,
      color: "text-green-600",
      bgColor: "bg-green-100",
      subtitle: `${completionRate}% completion rate`,
    },
    {
      title: "In Progress",
      value: inProgressTasks,
      icon: Activity,
      color: "text-yellow-600",
      bgColor: "bg-yellow-100",
    },
    {
      title: "Pending",
      value: pendingTasks,
      icon: Clock,
      color: "text-gray-600",
      bgColor: "bg-gray-100",
    },
    {
      title: "Critical Risk",
      value: criticalRiskTasks,
      icon: AlertTriangle,
      color: "text-red-600",
      bgColor: "bg-red-100",
      subtitle: `${highRiskTasks} high risk`,
    },
    {
      title: "Average Risk",
      value: `${averageRisk}%`,
      icon: TrendingUp,
      color: "text-orange-600",
      bgColor: "bg-orange-100",
    },
    {
      title: "Scheduled",
      value: scheduledTasks,
      icon: Calendar,
      color: "text-purple-600",
      bgColor: "bg-purple-100",
    },
    {
      title: "Upcoming Reviews",
      value: upcomingReviews,
      icon: Users,
      color: "text-indigo-600",
      bgColor: "bg-indigo-100",
      subtitle: "Next 30 days",
    },
  ]

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
      {stats.map((stat) => (
        <Card key={stat.title}>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">{stat.title}</CardTitle>
            <div className={`p-2 rounded-lg ${stat.bgColor}`}>
              <stat.icon className={`h-4 w-4 ${stat.color}`} />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stat.value}</div>
            {stat.subtitle && <p className="text-xs text-muted-foreground mt-1">{stat.subtitle}</p>}
          </CardContent>
        </Card>
      ))}
    </div>
  )
}
[V0_FILE]typescriptreact:file="components/dashboard/risk-distribution-chart.tsx" isMerged="true"
"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import type { Task } from "@/lib/types"
import { getRiskLevel } from "@/lib/utils"

interface RiskDistributionChartProps {
  tasks: Task[]
}

export function RiskDistributionChart({ tasks }: RiskDistributionChartProps) {
  // Calcular distribución de riesgos
  const riskDistribution = {
    Critical: tasks.filter((t) => getRiskLevel(t.current_risk) === "Critical").length,
    High: tasks.filter((t) => getRiskLevel(t.current_risk) === "High").length,
    "Medium-High": tasks.filter((t) => getRiskLevel(t.current_risk) === "Medium-High").length,
    Medium: tasks.filter((t) => getRiskLevel(t.current_risk) === "Medium").length,
    "Low-Medium": tasks.filter((t) => getRiskLevel(t.current_risk) === "Low-Medium").length,
    Low: tasks.filter((t) => getRiskLevel(t.current_risk) === "Low").length,
    "Very Low": tasks.filter((t) => getRiskLevel(t.current_risk) === "Very Low").length,
    Minimal: tasks.filter((t) => getRiskLevel(t.current_risk) === "Minimal").length,
  }

  const total = tasks.length
  const maxValue = Math.max(...Object.values(riskDistribution))

  const riskColors = {
    Critical: "bg-red-600",
    High: "bg-orange-600",
    "Medium-High": "bg-orange-500",
    Medium: "bg-amber-500",
    "Low-Medium": "bg-yellow-400",
    Low: "bg-lime-500",
    "Very Low": "bg-green-500",
    Minimal: "bg-green-700",
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Risk Distribution</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {Object.entries(riskDistribution).map(([level, count]) => {
            const percentage = total > 0 ? Math.round((count / total) * 100) : 0
            const barWidth = maxValue > 0 ? (count / maxValue) * 100 : 0

            return (
              <div key={level} className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="font-medium">{level}</span>
                  <span className="text-muted-foreground">
                    {count} ({percentage}%)
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full transition-all duration-500 ${
                      riskColors[level as keyof typeof riskColors]
                    }`}
                    style={{ width: `${barWidth}%` }}
                  />
                </div>
              </div>
            )
          })}
        </div>
      </CardContent>
    </Card>
  )
}
[V0_FILE]typescriptreact:file="components/dashboard/department-overview.tsx" isMerged="true"
"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import type { Task } from "@/lib/types"

interface DepartmentOverviewProps {
  tasks: Task[]
}

export function DepartmentOverview({ tasks }: DepartmentOverviewProps) {
  // Agrupar tareas por departamento
  const departmentStats = tasks.reduce(
    (acc, task) => {
      const dept = task.department || "Unknown"
      if (!acc[dept]) {
        acc[dept] = {
          total: 0,
          completed: 0,
          inProgress: 0,
          pending: 0,
          highRisk: 0,
        }
      }

      acc[dept].total++

      if (task.status.startsWith("Completed") || task.status === "Closed") {
        acc[dept].completed++
      } else if (task.status === "In Progress" || task.status === "Implementation In Progress") {
        acc[dept].inProgress++
      } else if (task.status === "Pending" || task.status === "Pending Ticket") {
        acc[dept].pending++
      }

      if (task.current_risk >= 75) {
        acc[dept].highRisk++
      }

      return acc
    },
    {} as Record<string, { total: number; completed: number; inProgress: number; pending: number; highRisk: number }>,
  )

  return (
    <Card>
      <CardHeader>
        <CardTitle>Department Overview</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {Object.entries(departmentStats).map(([dept, stats]) => {
            const completionRate = stats.total > 0 ? Math.round((stats.completed / stats.total) * 100) : 0

            return (
              <div key={dept} className="border rounded-lg p-4">
                <div className="flex items-center justify-between mb-2">
                  <h3 className="font-semibold">{dept}</h3>
                  <Badge variant="outline">{stats.total} tasks</Badge>
                </div>

                <div className="grid grid-cols-2 gap-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Completed:</span>
                    <span className="font-medium text-green-600">{stats.completed}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">In Progress:</span>
                    <span className="font-medium text-yellow-600">{stats.inProgress}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Pending:</span>
                    <span className="font-medium text-gray-600">{stats.pending}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">High Risk:</span>
                    <span className="font-medium text-red-600">{stats.highRisk}</span>
                  </div>
                </div>

                <div className="mt-3">
                  <div className="flex justify-between text-xs mb-1">
                    <span>Completion Rate</span>
                    <span>{completionRate}%</span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div
                      className="bg-green-500 h-2 rounded-full transition-all duration-500"
                      style={{ width: `${completionRate}%` }}
                    />
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      </CardContent>
    </Card>
  )
}
[V0_FILE]typescriptreact:file="components/dashboard/cis-controls-overview.tsx" isMerged="true"
"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import type { Task } from "@/lib/types"

interface CISControlsOverviewProps {
  tasks: Task[]
}

const cisControlNames: Record<number, string> = {
  1: "Inventory and Control of Enterprise Assets",
  2: "Inventory and Control of Software Assets",
  3: "Data Protection",
  4: "Secure Configuration",
  5: "Account Management",
  6: "Access Control Management",
  7: "Continuous Vulnerability Management",
  8: "Audit Log Management",
  9: "Email and Web Browser Protections",
  10: "Malware Defenses",
  11: "Data Recovery",
  12: "Network Infrastructure Management",
  13: "Security Awareness and Skills Training",
  14: "Security Operations Center",
  15: "Service Provider Management",
  16: "Application Software Security",
  17: "Incident Response Management",
  18: "Penetration Testing",
  19: "Compliance",
}

export function CISControlsOverview({ tasks }: CISControlsOverviewProps) {
  // Agrupar tareas por CIS Control
  const cisStats = tasks.reduce(
    (acc, task) => {
      const control = task.cis_control
      if (!acc[control]) {
        acc[control] = {
          total: 0,
          completed: 0,
          avgRisk: 0,
          totalRisk: 0,
        }
      }

      acc[control].total++
      acc[control].totalRisk += task.current_risk

      if (task.status.startsWith("Completed") || task.status === "Closed") {
        acc[control].completed++
      }

      return acc
    },
    {} as Record<number, { total: number; completed: number; avgRisk: number; totalRisk: number }>,
  )

  // Calcular riesgo promedio
  Object.keys(cisStats).forEach((control) => {
    const stats = cisStats[Number(control)]
    stats.avgRisk = Math.round(stats.totalRisk / stats.total)
  })

  // Ordenar por número de tareas
  const sortedControls = Object.entries(cisStats).sort(([, a], [, b]) => b.total - a.total)

  return (
    <Card>
      <CardHeader>
        <CardTitle>CIS Controls Implementation</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          {sortedControls.map(([control, stats]) => {
            const controlNum = Number(control)
            const completionRate = stats.total > 0 ? Math.round((stats.completed / stats.total) * 100) : 0

            return (
              <div key={control} className="space-y-2">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <span className="font-semibold text-sm">CIS {controlNum}</span>
                      <span className="text-xs text-muted-foreground">({stats.total} tasks)</span>
                    </div>
                    <p className="text-xs text-muted-foreground mt-0.5">
                      {cisControlNames[controlNum] || "Unknown Control"}
                    </p>
                  </div>
                  <div className="text-right">
                    <div className="text-sm font-medium">{completionRate}%</div>
                    <div className="text-xs text-muted-foreground">Avg Risk: {stats.avgRisk}%</div>
                  </div>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-1.5">
                  <div
                    className="bg-blue-500 h-1.5 rounded-full transition-all duration-500"
                    style={{ width: `${completionRate}%` }}
                  />
                </div>
              </div>
            )
          })}
        </div>
      </CardContent>
    </Card>
  )
}
[V0_FILE]typescriptreact:file="components/dashboard/recent-activities.tsx" isMerged="true"
"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import type { Task } from "@/lib/types"
import { formatDate, getRiskBadgeStyles } from "@/lib/utils"
import { Clock, CheckCircle, AlertTriangle } from "lucide-react"

interface RecentActivitiesProps {
  tasks: Task[]
}

export function RecentActivities({ tasks }: RecentActivitiesProps) {
  // Obtener las 10 tareas más recientes basadas en last_check
  const recentTasks = [...tasks]
    .sort((a, b) => new Date(b.last_check).getTime() - new Date(a.last_check).getTime())
    .slice(0, 10)

  const getStatusIcon = (status: string) => {
    if (status.startsWith("Completed") || status === "Closed") {
      return <CheckCircle className="h-4 w-4 text-green-500" />
    } else if (status === "In Progress" || status === "Implementation In Progress") {
      return <Clock className="h-4 w-4 text-yellow-500" />
    } else {
      return <AlertTriangle className="h-4 w-4 text-gray-500" />
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Recent Activities</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {recentTasks.map((task) => (
            <div key={task.id} className="flex items-start space-x-3 pb-3 border-b last:border-0 last:pb-0">
              <div className="mt-0.5">{getStatusIcon(task.status)}</div>
              <div className="flex-1 space-y-1">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <p className="text-sm font-medium leading-none">{task.summary}</p>
                    <p className="text-xs text-muted-foreground mt-1">{task.project_action}</p>
                  </div>
                  <Badge className={`ml-2 text-xs ${getRiskBadgeStyles(task.current_risk)}`}>
                    {task.current_risk}%
                  </Badge>
                </div>
                <div className="flex items-center gap-4 text-xs text-muted-foreground">
                  <span>{task.owner}</span>
                  <span>•</span>
                  <span>{formatDate(task.last_check)}</span>
                  <span>•</span>
                  <Badge variant="outline" className="text-xs">
                    {task.status}
                  </Badge>
                </div>
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  )
}
[V0_FILE]typescriptreact:file="components/dashboard/timeline-chart.tsx" isMerged="true"
"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import type { Task } from "@/lib/types"

interface TimelineChartProps {
  tasks: Task[]
}

export function TimelineChart({ tasks }: TimelineChartProps) {
  // Agrupar tareas por mes de creación
  const monthlyData = tasks.reduce(
    (acc, task) => {
      const date = new Date(task.creation_date)
      const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`

      if (!acc[monthKey]) {
        acc[monthKey] = {
          created: 0,
          completed: 0,
        }
      }

      acc[monthKey].created++

      if (task.status.startsWith("Completed") || task.status === "Closed") {
        const completionDate = task.completion_date ? new Date(task.completion_date) : new Date(task.last_check)
        const completionMonthKey = `${completionDate.getFullYear()}-${String(completionDate.getMonth() + 1).padStart(
          2,
          "0",
        )}`
        if (!acc[completionMonthKey]) {
          acc[completionMonthKey] = {
            created: 0,
            completed: 0,
          }
        }
        acc[completionMonthKey].completed++
      }

      return acc
    },
    {} as Record<string, { created: number; completed: number }>,
  )

  // Obtener los últimos 6 meses
  const months = Object.keys(monthlyData).sort().slice(-6)
  const maxValue = Math.max(...months.flatMap((month) => [monthlyData[month].created, monthlyData[month].completed]))

  const formatMonth = (monthKey: string) => {
    const [year, month] = monthKey.split("-")
    const date = new Date(Number(year), Number(month) - 1)
    return date.toLocaleDateString("en-US", { month: "short", year: "2-digit" })
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Task Timeline (Last 6 Months)</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {months.map((month) => {
            const data = monthlyData[month]
            const createdWidth = maxValue > 0 ? (data.created / maxValue) * 100 : 0
            const completedWidth = maxValue > 0 ? (data.completed / maxValue) * 100 : 0

            return (
              <div key={month} className="space-y-2">
                <div className="text-sm font-medium">{formatMonth(month)}</div>
                <div className="space-y-1">
                  <div className="flex items-center gap-2">
                    <span className="text-xs text-muted-foreground w-16">Created</span>
                    <div className="flex-1 bg-gray-200 rounded-full h-2">
                      <div
                        className="bg-blue-500 h-2 rounded-full transition-all duration-500"
                        style={{ width: `${createdWidth}%` }}
                      />
                    </div>
                    <span className="text-xs font-medium w-8 text-right">{data.created}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="text-xs text-muted-foreground w-16">Completed</span>
                    <div className="flex-1 bg-gray-200 rounded-full h-2">
                      <div
                        className="bg-green-500 h-2 rounded-full transition-all duration-500"
                        style={{ width: `${completedWidth}%` }}
                      />
                    </div>
                    <span className="text-xs font-medium w-8 text-right">{data.completed}</span>
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      </CardContent>
    </Card>
  )
}
[V0_FILE]typescriptreact:file="components/dashboard/dashboard.tsx" isMerged="true"
"use client"

import { DashboardStats } from "./dashboard-stats"
import { RiskDistributionChart } from "./risk-distribution-chart"
import { DepartmentOverview } from "./department-overview"
import { CISControlsOverview } from "./cis-controls-overview"
import { RecentActivities } from "./recent-activities"
import { TimelineChart } from "./timeline-chart"
import type { Task } from "@/lib/types"

interface DashboardProps {
  tasks: Task[]
}

export function Dashboard({ tasks }: DashboardProps) {
  return (
    <div className="space-y-6">
      {/* Estadísticas principales */}
      <DashboardStats tasks={tasks} />

      {/* Gráficos y visualizaciones */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <RiskDistributionChart tasks={tasks} />
        <TimelineChart tasks={tasks} />
      </div>

      {/* Resúmenes por departamento y CIS Controls */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <DepartmentOverview tasks={tasks} />
        <CISControlsOverview tasks={tasks} />
      </div>

      {/* Actividades recientes */}
      <RecentActivities tasks={tasks} />
    </div>
  )
}
[V0_FILE]typescript:file="app/api/personnel/[id]/route.ts" isMerged="true"
import { type NextRequest, NextResponse } from "next/server"
import { sql } from "@/lib/db"

export async function DELETE(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const id = params.id

    // Verificar si el personal existe
    const personnel = await sql`
      SELECT * FROM personnel WHERE id = ${id}
    `

    if (personnel.length === 0) {
      return NextResponse.json({ error: "Personnel not found" }, { status: 404 })
    }

    // Eliminar el personal
    await sql`
      DELETE FROM personnel WHERE id = ${id}
    `

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error("Error deleting personnel:", error)
    return NextResponse.json({ error: "Failed to delete personnel" }, { status: 500 })
  }
}

export async function PUT(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const id = params.id
    const { name, type } = await request.json()

    if (!name || !name.trim()) {
      return NextResponse.json({ error: "Name is required" }, { status: 400 })
    }

    if (!type || !["owners", "coordinators", "technicians"].includes(type)) {
      return NextResponse.json({ error: "Invalid type" }, { status: 400 })
    }

    // Verificar si el personal existe
    const personnel = await sql`
      SELECT * FROM personnel WHERE id = ${id}
    `

    if (personnel.length === 0) {
      return NextResponse.json({ error: "Personnel not found" }, { status: 404 })
    }

    // Actualizar el personal
    await sql`
      UPDATE personnel 
      SET name = ${name.trim()}, type = ${type}
      WHERE id = ${id}
    `

    // Devolver la lista actualizada
    const updatedList = await sql`
      SELECT * FROM personnel ORDER BY type, name
    `

    // Agrupar por tipo
    const owners = updatedList.filter((p) => p.type === "owners").map((p) => p.name)
    const coordinators = updatedList.filter((p) => p.type === "coordinators").map((p) => p.name)
    const technicians = updatedList.filter((p) => p.type === "technicians").map((p) => p.name)

    return NextResponse.json({
      owners,
      coordinators,
      technicians,
    })
  } catch (error) {
    console.error("Error updating personnel:", error)
    return NextResponse.json({ error: "Failed to update personnel" }, { status: 500 })
  }
}
[V0_FILE]typescript:file="app/api/personnel/route.ts" isEdit="true" isMerged="true"
import { type NextRequest, NextResponse } from "next/server"
import { sql } from "@/lib/db"

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const includeIds = searchParams.get("includeIds") === "true"

    const personnel = await sql`
      SELECT * FROM personnel
      ORDER BY type, name
    `

    if (includeIds) {
      // Devolver la lista completa con IDs para la gestión
      return NextResponse.json({
        personnel,
      })
    } else {
      // Formato original para compatibilidad con el resto de la aplicación
      const owners = personnel.filter((p) => p.type === "owners").map((p) => p.name)
      const coordinators = personnel.filter((p) => p.type === "coordinators").map((p) => p.name)
      const technicians = personnel.filter((p) => p.type === "technicians").map((p) => p.name)

      return NextResponse.json({
        owners,
        coordinators,
        technicians,
      })
    }
  } catch (error) {
    console.error("Error fetching personnel:", error)
    return NextResponse.json({ error: "Failed to fetch personnel" }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    const { type, name } = await request.json()

    if (!name || !name.trim()) {
      return NextResponse.json({ error: "Name is required" }, { status: 400 })
    }

    if (!type || !["owners", "coordinators", "technicians"].includes(type)) {
      return NextResponse.json({ error: "Invalid type" }, { status: 400 })
    }

    // Check if already exists
    const existing = await sql`
      SELECT * FROM personnel 
      WHERE name = ${name.trim()} AND type = ${type}
    `

    if (existing.length === 0) {
      // Insert new personnel
      await sql`
        INSERT INTO personnel (name, type)
        VALUES (${name.trim()}, ${type})
      `
    }

    // Return updated list
    return GET(request)
  } catch (error) {
    console.error("Error adding personnel:", error)
    return NextResponse.json({ error: "Failed to add personnel" }, { status: 500 })
  }
}
[V0_FILE]typescriptreact:file="components/task-form.tsx" isEdit="true" isMerged="true"
"use client"

import type React from "react"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog"
import { Calendar } from "@/components/ui/calendar"
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover"
import type { Task, TaskStatus, PersonnelLists } from "@/lib/types"
import { calculateRawRisk, calculateCurrentRisk, cn } from "@/lib/utils"
import { Plus, CalendarIcon } from "lucide-react"
import { format } from "date-fns"
import { es } from "date-fns/locale"
import { PersonnelCombobox } from "./personnel-combobox"
import { api } from "@/lib/api"

interface TaskFormProps {
  task?: Task
  onSubmit: (task: Partial<Task>) => void
  onCancel: () => void
  isOpen: boolean
  setIsOpen: (open: boolean) => void
}

// Actualizar las opciones de estado en el formulario
const statusOptions: TaskStatus[] = [
  "Pending Ticket",
  "Pending",
  "Scheduled",
  "Request for Authorization",
  "In Progress",
  "Implementation In Progress",
  "Completed 2025",
  "Completed 2024",
  "Closed",
]

// Mapeo de tipos de personal en singular a plural
const typeMapping: Record<string, keyof PersonnelLists> = {
  owner: "owners",
  coordinator: "coordinators",
  technician: "technicians",
}

export function TaskForm({ task, onSubmit, onCancel, isOpen, setIsOpen }: TaskFormProps) {
  const [formData, setFormData] = useState<Partial<Task>>(
    task || {
      ticket: "",
      cis_control: 1,
      project_action: "",
      summary: "",
      description: "",
      risk: "",
      impact: "",
      raw_probability: 50,
      raw_impact: 50,
      avoid: 0,
      mitigate: 0,
      transfer: 0,
      accept: null,
      treatment: "",
      treated_probability: 30,
      treated_impact: 30,
      next_review: "",
      department: "",
      owner: "",
      coordinator: "",
      technician: "",
      status: "Pending",
      last_check: new Date().toISOString().split("T")[0],
      comments: "",
    },
  )

  const [personnel, setPersonnel] = useState<PersonnelLists>({
    owners: [],
    coordinators: [],
    technicians: [],
  })

  const [selectedDate, setSelectedDate] = useState<Date | undefined>(
    formData.next_review && formData.next_review !== "N/A" ? new Date(formData.next_review) : undefined,
  )

  // Reset form when task changes or dialog opens/closes
  useEffect(() => {
    if (isOpen) {
      setFormData(
        task || {
          ticket: "",
          cis_control: 1,
          project_action: "",
          summary: "",
          description: "",
          risk: "",
          impact: "",
          raw_probability: 50,
          raw_impact: 50,
          avoid: 0,
          mitigate: 0,
          transfer: 0,
          accept: null,
          treatment: "",
          treated_probability: 30,
          treated_impact: 30,
          next_review: "",
          department: "",
          owner: "",
          coordinator: "",
          technician: "",
          status: "Pending",
          last_check: new Date().toISOString().split("T")[0],
          comments: "",
        },
      )
      setSelectedDate(task?.next_review && task.next_review !== "N/A" ? new Date(task.next_review) : undefined)

      // Actualizar la lista de personal cada vez que se abre el formulario
      fetchPersonnel()
    }
  }, [task, isOpen])

  const fetchPersonnel = async () => {
    try {
      const data = await api.getPersonnel()
      setPersonnel({
        owners: data.owners || [],
        coordinators: data.coordinators || [],
        technicians: data.technicians || [],
      })
    } catch (error) {
      console.error("Error fetching personnel:", error)
    }
  }

  // Modificar la función addPersonnel para convertir el tipo singular a plural
  const addPersonnel = async (type: string, name: string): Promise<void> => {
    if (!name.trim()) return

    // Convertir el tipo singular a plural
    const pluralType = typeMapping[type] || type

    console.log(`Tipo original: ${type}, Tipo convertido: ${pluralType}`)

    try {
      const updatedPersonnel = await api.addPersonnel(pluralType, name.trim())
      setPersonnel(updatedPersonnel)

      // Actualizar directamente el valor en el formulario
      setFormData((prev) => {
        const newFormData = { ...prev, [type]: name.trim() }
        console.log("Formulario actualizado:", newFormData)
        return newFormData
      })
    } catch (error) {
      console.error("Error adding personnel:", error)
      throw error // Re-lanzar el error para que pueda ser capturado por el componente hijo
    }
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    const rawRisk = calculateRawRisk(formData.raw_probability || 0, formData.raw_impact || 0)
    const currentRisk = calculateCurrentRisk(formData.treated_probability || 0, formData.treated_impact || 0)

    const taskToSubmit = {
      ...formData,
      raw_risk: rawRisk,
      current_risk: currentRisk,
      next_review: selectedDate ? format(selectedDate, "yyyy-MM-dd") : "N/A",
    }

    console.log("Submitting task:", taskToSubmit)
    onSubmit(taskToSubmit)
  }

  const handleInputChange = (field: keyof Task, value: any) => {
    setFormData((prev) => {
      const newData = { ...prev, [field]: value }
      return newData
    })
  }

  // Función para asegurar que los valores numéricos se muestren correctamente
  const formatNumberValue = (value: number | undefined): string => {
    // Si el valor es 0 o undefined, devolver "0"
    if (value === 0 || value === undefined) return "0"
    // De lo contrario, devolver el valor como string
    return value.toString()
  }

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogTrigger asChild>
        <Button>
          <Plus className="w-4 h-4 mr-2" />
          New Task
        </Button>
      </DialogTrigger>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{task ? "Edit Task" : "New Task"}</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label htmlFor="ticket">Ticket (Optional)</Label>
              <Input
                id="ticket"
                value={formData.ticket || ""}
                onChange={(e) => handleInputChange("ticket", e.target.value)}
                placeholder="CRQ000123456"
              />
            </div>
            <div>
              <Label htmlFor="cis_control">CIS Control</Label>
              <Select
                value={formData.cis_control?.toString()}
                onValueChange={(value) => handleInputChange("cis_control", Number.parseInt(value))}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select CIS Control" />
                </SelectTrigger>
                <SelectContent className="max-h-60">
                  <SelectItem value="1">1 - Inventory and Control of Enterprise Assets</SelectItem>
                  <SelectItem value="2">2 - Inventory and Control of Software Assets</SelectItem>
                  <SelectItem value="3">3 - Data Protection</SelectItem>
                  <SelectItem value="4">4 - Secure Configuration of Enterprise Assets and Software</SelectItem>
                  <SelectItem value="5">5 - Account Management</SelectItem>
                  <SelectItem value="6">6 - Access Control Management</SelectItem>
                  <SelectItem value="7">7 - Continuous Vulnerability Management</SelectItem>
                  <SelectItem value="8">8 - Audit Log Management</SelectItem>
                  <SelectItem value="9">9 - Email and Web Browser Protections</SelectItem>
                  <SelectItem value="10">10 - Malware Defenses</SelectItem>
                  <SelectItem value="11">11 - Data Recovery</SelectItem>
                  <SelectItem value="12">12 - Network Infrastructure Management</SelectItem>
                  <SelectItem value="13">13 - Security Awareness and Skills Training</SelectItem>
                  <SelectItem value="14">14 - Security Operations Center (SOC) Operations</SelectItem>
                  <SelectItem value="15">15 - Service Provider Management</SelectItem>
                  <SelectItem value="16">16 - Application Software Security</SelectItem>
                  <SelectItem value="17">17 - Incident Response Management</SelectItem>
                  <SelectItem value="18">18 - Penetration Testing</SelectItem>
                  <SelectItem value="19">Compliance</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label htmlFor="project_action">PROJECT/ACTION</Label>
              <Input
                id="project_action"
                value={formData.project_action || ""}
                onChange={(e) => handleInputChange("project_action", e.target.value)}
                required
              />
            </div>
            <div>
              <Label htmlFor="status">STATUS</Label>
              <Select value={formData.status} onValueChange={(value) => handleInputChange("status", value)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {statusOptions.map((status) => (
                    <SelectItem key={status} value={status}>
                      {status}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div>
            <Label htmlFor="summary">Summary</Label>
            <Input
              id="summary"
              value={formData.summary || ""}
              onChange={(e) => handleInputChange("summary", e.target.value)}
              required
            />
          </div>

          <div>
            <Label htmlFor="description">Description</Label>
            <Textarea
              id="description"
              value={formData.description || ""}
              onChange={(e) => handleInputChange("description", e.target.value)}
              required
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label htmlFor="risk">Risk</Label>
              <Input
                id="risk"
                value={formData.risk || ""}
                onChange={(e) => handleInputChange("risk", e.target.value)}
              />
            </div>
            <div>
              <Label htmlFor="impact">Impact</Label>
              <Input
                id="impact"
                value={formData.impact || ""}
                onChange={(e) => handleInputChange("impact", e.target.value)}
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div>
              <Label htmlFor="raw_probability">Raw Probability (%)</Label>
              <Input
                id="raw_probability"
                type="number"
                min="0"
                max="100"
                value={formatNumberValue(formData.raw_probability)}
                onChange={(e) => handleInputChange("raw_probability", Number.parseInt(e.target.value) || 0)}
                required
              />
              <p className="text-xs text-gray-500 mt-1">
                Raw Risk: {calculateRawRisk(formData.raw_probability || 0, formData.raw_impact || 0)}%
              </p>
            </div>
            <div>
              <Label htmlFor="raw_impact">Raw Impact (%)</Label>
              <Input
                id="raw_impact"
                type="number"
                min="0"
                max="100"
                value={formatNumberValue(formData.raw_impact)}
                onChange={(e) => handleInputChange("raw_impact", Number.parseInt(e.target.value) || 0)}
                required
              />
            </div>
            <div>
              <Label htmlFor="treated_probability">Treated Probability (%)</Label>
              <Input
                id="treated_probability"
                type="number"
                min="0"
                max="100"
                value={formatNumberValue(formData.treated_probability)}
                onChange={(e) => handleInputChange("treated_probability", Number.parseInt(e.target.value) || 0)}
                required
              />
              <p className="text-xs text-gray-500 mt-1">
                Current Risk: {calculateCurrentRisk(formData.treated_probability || 0, formData.treated_impact || 0)}%
              </p>
            </div>
            <div>
              <Label htmlFor="treated_impact">Treated Impact (%)</Label>
              <Input
                id="treated_impact"
                type="number"
                min="0"
                max="100"
                value={formatNumberValue(formData.treated_impact)}
                onChange={(e) => handleInputChange("treated_impact", Number.parseInt(e.target.value) || 0)}
                required
              />
            </div>
          </div>

          <div>
            <Label htmlFor="treatment">TREATMENT/TASK</Label>
            <Textarea
              id="treatment"
              value={formData.treatment || ""}
              onChange={(e) => handleInputChange("treatment", e.target.value)}
              required
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <Label htmlFor="department">DPT</Label>
              <Select value={formData.department} onValueChange={(value) => handleInputChange("department", value)}>
                <SelectTrigger>
                  <SelectValue placeholder="Select Department" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Seguridad">Security</SelectItem>
                  <SelectItem value="Infraestructura">Infrastructure</SelectItem>
                  <SelectItem value="Operaciones">Operations</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <PersonnelCombobox
              type="owner"
              value={formData.owner || ""}
              placeholder="Select Owner"
              label="OWNER"
              options={personnel.owners}
              onChange={(value) => handleInputChange("owner", value)}
              onAddNew={addPersonnel}
            />
            <PersonnelCombobox
              type="coordinator"
              value={formData.coordinator || ""}
              placeholder="Select Coordinator"
              label="COORDINATOR"
              options={personnel.coordinators}
              onChange={(value) => handleInputChange("coordinator", value)}
              onAddNew={addPersonnel}
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <PersonnelCombobox
              type="technician"
              value={formData.technician || ""}
              placeholder="Select Technician"
              label="TECHNICIAN"
              options={personnel.technicians}
              onChange={(value) => handleInputChange("technician", value)}
              onAddNew={addPersonnel}
            />
            <div>
              <Label>Next Review</Label>
              <Popover>
                <PopoverTrigger asChild>
                  <Button
                    variant="outline"
                    className={cn(
                      "w-full justify-start text-left font-normal",
                      !selectedDate && "text-muted-foreground",
                    )}
                  >
                    <CalendarIcon className="mr-2 h-4 w-4" />
                    {selectedDate ? format(selectedDate, "PPP", { locale: es }) : "Select date"}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0">
                  <Calendar mode="single" selected={selectedDate} onSelect={setSelectedDate} initialFocus />
                </PopoverContent>
              </Popover>
            </div>
          </div>

          <div>
            <Label htmlFor="comments">COMMENTS</Label>
            <Textarea
              id="comments"
              value={formData.comments || ""}
              onChange={(e) => handleInputChange("comments", e.target.value)}
            />
          </div>

          <div className="flex justify-end space-x-2">
            <Button type="button" variant="outline" onClick={() => setIsOpen(false)}>
              Cancel
            </Button>
            <Button type="submit">{task ? "Update" : "Create"} Task</Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
[V0_FILE]typescriptreact:file="components/personnel-management.tsx" isEdit="true" isMerged="true"
"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Badge } from "@/components/ui/badge"
import { Edit, Trash2, Plus, Users } from "lucide-react"
import { useToast } from "@/components/ui/use-toast"
import { api } from "@/lib/api"

interface Personnel {
  id: string
  name: string
  type: string
  created_at: string
}

interface PersonnelManagementProps {
  onPersonnelUpdate?: () => void
}

export function PersonnelManagement({ onPersonnelUpdate }: PersonnelManagementProps) {
  const [personnel, setPersonnel] = useState<Personnel[]>([])
  const [loading, setLoading] = useState(true)
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false)
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false)
  const [newPersonName, setNewPersonName] = useState("")
  const [newPersonType, setNewPersonType] = useState("owners")
  const [editingPerson, setEditingPerson] = useState<Personnel | null>(null)
  const [activeTab, setActiveTab] = useState("owners")
  const { toast } = useToast()

  useEffect(() => {
    fetchPersonnel()
  }, [])

  const fetchPersonnel = async () => {
    try {
      setLoading(true)
      const data = await api.getPersonnelWithIds()
      setPersonnel(data.personnel || [])
    } catch (error) {
      console.error("Error fetching personnel:", error)
      toast({
        title: "Error",
        description: "Error al cargar el personal. Por favor, recarga la página.",
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  const handleAddPerson = async () => {
    if (!newPersonName.trim()) {
      toast({
        title: "Error",
        description: "El nombre es obligatorio.",
        variant: "destructive",
      })
      return
    }

    try {
      await api.addPersonnel(newPersonType, newPersonName.trim())
      await fetchPersonnel()
      setIsAddDialogOpen(false)
      setNewPersonName("")

      // Notificar a la aplicación que el personal ha sido actualizado
      if (onPersonnelUpdate) {
        onPersonnelUpdate()
      }

      toast({
        title: "Personal añadido",
        description: `${newPersonName.trim()} ha sido añadido como ${getTypeLabel(newPersonType)}.`,
      })
    } catch (error) {
      console.error("Error adding personnel:", error)
      toast({
        title: "Error",
        description: "Error al añadir personal. Por favor, inténtalo de nuevo.",
        variant: "destructive",
      })
    }
  }

  const handleEditPerson = async () => {
    if (!editingPerson || !editingPerson.name.trim()) {
      toast({
        title: "Error",
        description: "El nombre es obligatorio.",
        variant: "destructive",
      })
      return
    }

    try {
      await api.updatePersonnel(editingPerson.id, editingPerson.type, editingPerson.name.trim())
      await fetchPersonnel()
      setIsEditDialogOpen(false)
      setEditingPerson(null)

      // Notificar a la aplicación que el personal ha sido actualizado
      if (onPersonnelUpdate) {
        onPersonnelUpdate()
      }

      toast({
        title: "Personal actualizado",
        description: `${editingPerson.name.trim()} ha sido actualizado correctamente.`,
      })
    } catch (error) {
      console.error("Error updating personnel:", error)
      toast({
        title: "Error",
        description: "Error al actualizar personal. Por favor, inténtalo de nuevo.",
        variant: "destructive",
      })
    }
  }

  const handleDeletePerson = async (id: string, name: string) => {
    if (!confirm(`¿Estás seguro de que deseas eliminar a ${name}?`)) return

    try {
      await api.deletePersonnel(id)
      await fetchPersonnel()

      // Notificar a la aplicación que el personal ha sido actualizado
      if (onPersonnelUpdate) {
        onPersonnelUpdate()
      }

      toast({
        title: "Personal eliminado",
        description: `${name} ha sido eliminado correctamente.`,
      })
    } catch (error) {
      console.error("Error deleting personnel:", error)
      toast({
        title: "Error",
        description: "Error al eliminar personal. Por favor, inténtalo de nuevo.",
        variant: "destructive",
      })
    }
  }

  const getTypeLabel = (type: string) => {
    switch (type) {
      case "owners":
        return "Propietario"
      case "coordinators":
        return "Coordinador"
      case "technicians":
        return "Técnico"
      default:
        return type
    }
  }

  const filteredPersonnel = personnel.filter((person) => person.type === activeTab)

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Users className="h-5 w-5 text-blue-600" />
          <h2 className="text-xl font-bold">Gestión de Personal</h2>
        </div>
        <Button onClick={() => setIsAddDialogOpen(true)}>
          <Plus className="h-4 w-4 mr-2" />
          Añadir Personal
        </Button>
      </div>

      <Tabs defaultValue="owners" onValueChange={setActiveTab}>
        <TabsList>
          <TabsTrigger value="owners">
            Propietarios
            <Badge variant="secondary" className="ml-2">
              {personnel.filter((p) => p.type === "owners").length}
            </Badge>
          </TabsTrigger>
          <TabsTrigger value="coordinators">
            Coordinadores
            <Badge variant="secondary" className="ml-2">
              {personnel.filter((p) => p.type === "coordinators").length}
            </Badge>
          </TabsTrigger>
          <TabsTrigger value="technicians">
            Técnicos
            <Badge variant="secondary" className="ml-2">
              {personnel.filter((p) => p.type === "technicians").length}
            </Badge>
          </TabsTrigger>
        </TabsList>

        <TabsContent value={activeTab}>
          <Card>
            <CardHeader>
              <CardTitle>{getTypeLabel(activeTab)}</CardTitle>
            </CardHeader>
            <CardContent>
              {loading ? (
                <div className="flex justify-center p-4">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
                </div>
              ) : filteredPersonnel.length === 0 ? (
                <div className="text-center p-4 text-gray-500">
                  No hay {getTypeLabel(activeTab).toLowerCase()}s registrados.
                </div>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Nombre</TableHead>
                      <TableHead>Fecha de Creación</TableHead>
                      <TableHead className="text-right">Acciones</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredPersonnel.map((person) => (
                      <TableRow key={person.id}>
                        <TableCell className="font-medium">{person.name}</TableCell>
                        <TableCell>{new Date(person.created_at).toLocaleDateString()}</TableCell>
                        <TableCell className="text-right">
                          <div className="flex justify-end gap-2">
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => {
                                setEditingPerson(person)
                                setIsEditDialogOpen(true)
                              }}
                            >
                              <Edit className="h-4 w-4" />
                            </Button>
                            <Button
                              size="sm"
                              variant="outline"
                              className="text-red-500 hover:text-red-700"
                              onClick={() => handleDeletePerson(person.id, person.name)}
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Diálogo para añadir personal */}
      <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Añadir Personal</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="name">Nombre</Label>
              <Input
                id="name"
                value={newPersonName}
                onChange={(e) => setNewPersonName(e.target.value)}
                placeholder="Nombre completo"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="type">Tipo</Label>
              <Select value={newPersonType} onValueChange={setNewPersonType}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="owners">Propietario</SelectItem>
                  <SelectItem value="coordinators">Coordinador</SelectItem>
                  <SelectItem value="technicians">Técnico</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsAddDialogOpen(false)}>
              Cancelar
            </Button>
            <Button onClick={handleAddPerson}>Añadir</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Diálogo para editar personal */}
      <Dialog open={isEditDialogOpen} onOpenChange={setIsEditDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Editar Personal</DialogTitle>
          </DialogHeader>
          {editingPerson && (
            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label htmlFor="edit-name">Nombre</Label>
                <Input
                  id="edit-name"
                  value={editingPerson.name}
                  onChange={(e) => setEditingPerson({ ...editingPerson, name: e.target.value })}
                  placeholder="Nombre completo"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="edit-type">Tipo</Label>
                <Select
                  value={editingPerson.type}
                  onValueChange={(value) => setEditingPerson({ ...editingPerson, type: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="owners">Propietario</SelectItem>
                    <SelectItem value="coordinators">Coordinador</SelectItem>
                    <SelectItem value="technicians">Técnico</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
          )}
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsEditDialogOpen(false)}>
              Cancelar
            </Button>
            <Button onClick={handleEditPerson}>Guardar</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
[V0_FILE]typescriptreact:file="lib/utils.ts" isEdit="true" isQuickEdit="true" isMerged="true"
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"
// Añadir la importación de exceljs al principio del archivo
import ExcelJS from "exceljs"
import type { Task } from "./types"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function calculateRawRisk(probability: number, impact: number): number {
  // Fórmula correcta: (probabilidad/100) * (impacto/100) * 100
  // Ejemplo: 10% probabilidad * 10% impacto = 1% riesgo
  return Math.round((probability / 100) * (impact / 100) * 100)
}

export function calculateCurrentRisk(probability: number, impact: number): number {
  // Fórmula correcta: (probabilidad/100) * (impacto/100) * 100
  // Ejemplo: 10% probabilidad * 10% impacto = 1% riesgo
  return Math.round((probability / 100) * (impact / 100) * 100)
}

export type RiskLevel = "Minimal" | "Very Low" | "Low" | "Low-Medium" | "Medium" | "Medium-High" | "High" | "Critical"

export function getRiskLevel(risk: number): RiskLevel {
  if (risk <= 12.5) return "Minimal"
  if (risk <= 25) return "Very Low"
  if (risk <= 37.5) return "Low"
  if (risk <= 50) return "Low-Medium"
  if (risk <= 62.5) return "Medium"
  if (risk <= 75) return "Medium-High"
  if (risk <= 87.5) return "High"
  return "Critical"
}

export function getRiskColor(risk: number): string {
  if (risk <= 12.5) {
    // Verde oscuro - Minimal (0-12.5%)
    return "bg-green-700 text-white border-green-700"
  }
  if (risk <= 25) {
    // Verde - Very Low (12.5-25%)
    return "bg-green-500 text-white border-green-500"
  }
  if (risk <= 37.5) {
    // Verde claro - Low (25-37.5%)
    return "bg-lime-500 text-white border-lime-500"
  }
  if (risk <= 50) {
    // Amarillo - Low-Medium (37.5-50%)
    return "bg-yellow-400 text-gray-900 border-yellow-400"
  }
  if (risk <= 62.5) {
    // Amarillo oscuro - Medium (50-62.5%)
    return "bg-amber-500 text-white border-amber-500"
  }
  if (risk <= 75) {
    // Naranja - Medium-High (62.5-75%)
    return "bg-orange-500 text-white border-orange-500"
  }
  if (risk <= 87.5) {
    // Naranja rojizo - High (75-87.5%)
    return "bg-orange-600 text-white border-orange-600"
  }
  // Rojo - Critical (87.5-100%)
  return "bg-red-600 text-white border-red-600"
}

export function getRiskBadgeStyles(risk: number): string {
  const baseStyles = "font-semibold px-2.5 py-0.5 rounded-md border"
  return `${baseStyles} ${getRiskColor(risk)}`
}

export function formatDate(dateString: string): string {
  return new Date(dateString).toLocaleDateString("es-ES")
}

export function exportToCSV(tasks: Task[]): string {
  const headers = Object.keys(tasks[0] || {})
  const csvContent = [
    headers.join(","),
    ...tasks.map((task) => headers.map((header) => JSON.stringify(task[header as keyof Task] || "")).join(",")),
  ].join("\n")

  return csvContent
}

// Añadir la función de exportación a Excel al final del archivo
export async function exportTasksToExcel(tasks: Task[]): Promise<void> {
  // Crear un nuevo libro de trabajo
  const workbook = new ExcelJS.Workbook()
  const worksheet = workbook.addWorksheet("Tareas")

  // Definir las columnas
  worksheet.columns = [
    { header: "Ticket", key: "ticket", width: 15 },
    { header: "Resumen", key: "summary", width: 40 },
    { header: "Proyecto/Acción", key: "project_action", width: 20 },
    { header: "Estado", key: "status", width: 20 },
    { header: "Riesgo Actual", key: "current_risk", width: 15 },
    { header: "Nivel de Riesgo", key: "risk_level", width: 15 },
    { header: "Propietario", key: "owner", width: 20 },
    { header: "Departamento", key: "department", width: 20 },
    { header: "Coordinador", key: "coordinator", width: 20 },
    { header: "Técnico", key: "technician", width: 20 },
    { header: "Última Revisión", key: "last_check", width: 15 },
    { header: "Fecha de Creación", key: "creation_date", width: 15 },
    { header: "Fecha de Completado", key: "completion_date", width: 15 },
  ]

  // Aplicar estilos al encabezado
  worksheet.getRow(1).font = { bold: true }
  worksheet.getRow(1).fill = {
    type: "pattern",
    pattern: "solid",
    fgColor: { argb: "FFE0E0E0" },
  }

  // Añadir los datos
  tasks.forEach((task) => {
    // Añadir una fila por cada tarea con los datos formateados
    worksheet.addRow({
      ticket: task.ticket,
      summary: task.summary,
      project_action: task.project_action,
      status: task.status,
      current_risk: task.current_risk,
      risk_level: getRiskLevel(task.current_risk),
      owner: task.owner,
      department: task.department,
      coordinator: task.coordinator,
      technician: task.technician,
      last_check: formatDate(task.last_check),
      creation_date: formatDate(task.creation_date),
      completion_date: task.completion_date ? formatDate(task.completion_date) : "",
    })
  })

  // Aplicar bordes a todas las celdas con datos
  worksheet.eachRow((row, rowNumber) => {
    row.eachCell((cell) => {
      cell.border = {
        top: { style: "thin" },
        left: { style: "thin" },
        bottom: { style: "thin" },
        right: { style: "thin" },
      }
    })
  })

  // Aplicar formato condicional para el riesgo
  worksheet.getColumn("current_risk").eachCell((cell, rowNumber) => {
    if (rowNumber > 1) {
      // Ignorar el encabezado
      const riskValue = cell.value as number

      // Aplicar color de fondo según el nivel de riesgo
      if (riskValue <= 12.5) {
        cell.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FF008000" } } // Verde oscuro
        cell.font = { color: { argb: "FFFFFFFF" } }
      } else if (riskValue <= 25) {
        cell.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FF10B981" } } // Verde
        cell.font = { color: { argb: "FFFFFFFF" } }
      } else if (riskValue <= 37.5) {
        cell.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FF84CC16" } } // Verde claro
        cell.font = { color: { argb: "FFFFFFFF" } }
      } else if (riskValue <= 50) {
        cell.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FFEAB308" } } // Amarillo
        cell.font = { color: { argb: "FF000000" } }
      } else if (riskValue <= 62.5) {
        cell.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FFF59E0B" } } // Amarillo oscuro
        cell.font = { color: { argb: "FFFFFFFF" } }
      } else if (riskValue <= 75) {
        cell.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FFF97316" } } // Naranja
        cell.font = { color: { argb: "FFFFFFFF" } }
      } else if (riskValue <= 87.5) {
        cell.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FFEA580C" } } // Naranja rojizo
        cell.font = { color: { argb: "FFFFFFFF" } }
      } else {
        cell.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FFDC2626" } } // Rojo
        cell.font = { color: { argb: "FFFFFFFF" } }
      }
    }
  })

  // Generar el archivo y descargarlo
  const buffer = await workbook.xlsx.writeBuffer()
  const blob = new Blob([buffer], { type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" })
  const url = window.URL.createObjectURL(blob)
  const a = document.createElement("a")
  a.href = url
  a.download = `cybersec_tasks_${new Date().toISOString().split("T")[0]}.xlsx`
  a.click()
  window.URL.revokeObjectURL(url)
}
[V0_FILE]typescriptreact:file="components/task-table.tsx" isEdit="true" isMerged="true"
"use client"

import type { Task } from "@/lib/types"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Checkbox } from "@/components/ui/checkbox"
import { getRiskBadgeStyles, formatDate } from "@/lib/utils"
import { Edit, Trash2 } from "lucide-react"

interface TaskTableProps {
  tasks: Task[]
  onEditTask: (task: Task) => void
  onDeleteTask: (id: string) => void
  selectedTaskIds?: string[]
  onSelectTask?: (id: string, selected: boolean) => void
}

export function TaskTable({ tasks, onEditTask, onDeleteTask, selectedTaskIds = [], onSelectTask }: TaskTableProps) {
  const hasSelectionEnabled = !!onSelectTask

  const handleSelectAllTasks = (checked: boolean) => {
    if (!onSelectTask) return

    if (checked) {
      // Seleccionar todas las tareas
      tasks.forEach((task) => onSelectTask(task.id, true))
    } else {
      // Deseleccionar todas las tareas
      tasks.forEach((task) => onSelectTask(task.id, false))
    }
  }

  return (
    <div className="border rounded-lg overflow-hidden">
      <Table>
        <TableHeader>
          <TableRow>
            {hasSelectionEnabled && (
              <TableHead className="w-[50px]">
                <Checkbox
                  checked={tasks.length > 0 && selectedTaskIds.length === tasks.length}
                  indeterminate={selectedTaskIds.length > 0 && selectedTaskIds.length < tasks.length}
                  onCheckedChange={(checked) => handleSelectAllTasks(!!checked)}
                  aria-label="Select all tasks"
                />
              </TableHead>
            )}
            <TableHead>Ticket</TableHead>
            <TableHead>Summary</TableHead>
            <TableHead>PROJECT/ACTION</TableHead>
            <TableHead>STATUS</TableHead>
            <TableHead>Current Risk</TableHead>
            <TableHead>OWNER</TableHead>
            <TableHead>DPT</TableHead>
            <TableHead>LAST CHECK</TableHead>
            <TableHead>Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {tasks.map((task) => (
            <TableRow key={task.id} className={selectedTaskIds.includes(task.id) ? "bg-gray-50" : ""}>
              {hasSelectionEnabled && (
                <TableCell>
                  <Checkbox
                    checked={selectedTaskIds.includes(task.id)}
                    onCheckedChange={(checked) => onSelectTask && onSelectTask(task.id, !!checked)}
                    aria-label={`Select task ${task.summary}`}
                  />
                </TableCell>
              )}
              <TableCell className="font-medium">{task.ticket}</TableCell>
              <TableCell>{task.summary}</TableCell>
              <TableCell>{task.project_action}</TableCell>
              <TableCell>
                <Badge variant="outline">{task.status}</Badge>
              </TableCell>
              <TableCell>
                <Badge className={getRiskBadgeStyles(task.current_risk)}>{task.current_risk}%</Badge>
              </TableCell>
              <TableCell>{task.owner}</TableCell>
              <TableCell>{task.department}</TableCell>
              <TableCell>{formatDate(task.last_check)}</TableCell>
              <TableCell>
                <div className="flex gap-2">
                  <Button size="sm" variant="outline" onClick={() => onEditTask(task)}>
                    <Edit className="w-4 h-4" />
                  </Button>
                  <Button size="sm" variant="outline" onClick={() => onDeleteTask(task.id)}>
                    <Trash2 className="w-4 h-4" />
                  </Button>
                </div>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  )
}
[V0_FILE]typescriptreact:file="components/completed-tasks-table.tsx" isEdit="true" isMerged="true"
"use client"

import type { Task } from "@/lib/types"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Checkbox } from "@/components/ui/checkbox"
import { getRiskBadgeStyles, formatDate } from "@/lib/utils"
import { Edit, Trash2 } from "lucide-react"

interface CompletedTasksTableProps {
  tasks: Task[]
  year: string
  onEditTask: (task: Task) => void
  onDeleteTask: (id: string) => void
  selectedTaskIds?: string[]
  onSelectTask?: (id: string, selected: boolean) => void
}

export function CompletedTasksTable({
  tasks,
  year,
  onEditTask,
  onDeleteTask,
  selectedTaskIds = [],
  onSelectTask,
}: CompletedTasksTableProps) {
  const hasSelectionEnabled = !!onSelectTask
  const completedTasks = tasks.filter((task) => task.status === `Completed ${year}`)

  if (completedTasks.length === 0) {
    return null
  }

  const handleSelectAllTasks = (checked: boolean) => {
    if (!onSelectTask) return

    if (checked) {
      // Seleccionar todas las tareas completadas
      completedTasks.forEach((task) => onSelectTask(task.id, true))
    } else {
      // Deseleccionar todas las tareas completadas
      completedTasks.forEach((task) => onSelectTask(task.id, false))
    }
  }

  return (
    <div className="mt-8">
      <h2 className="text-xl font-bold mb-4">Completed Tasks {year}</h2>
      <div className="border rounded-lg overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow>
              {hasSelectionEnabled && (
                <TableHead className="w-[50px]">
                  <Checkbox
                    checked={
                      completedTasks.length > 0 && completedTasks.every((task) => selectedTaskIds.includes(task.id))
                    }
                    indeterminate={
                      completedTasks.some((task) => selectedTaskIds.includes(task.id)) &&
                      !completedTasks.every((task) => selectedTaskIds.includes(task.id))
                    }
                    onCheckedChange={(checked) => handleSelectAllTasks(!!checked)}
                    aria-label={`Select all completed tasks ${year}`}
                  />
                </TableHead>
              )}
              <TableHead>Ticket</TableHead>
              <TableHead>Summary</TableHead>
              <TableHead>PROJECT/ACTION</TableHead>
              <TableHead>STATUS</TableHead>
              <TableHead>Current Risk</TableHead>
              <TableHead>OWNER</TableHead>
              <TableHead>DPT</TableHead>
              <TableHead>LAST CHECK</TableHead>
              <TableHead>Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {completedTasks.map((task) => (
              <TableRow key={task.id} className={selectedTaskIds.includes(task.id) ? "bg-gray-50" : ""}>
                {hasSelectionEnabled && (
                  <TableCell>
                    <Checkbox
                      checked={selectedTaskIds.includes(task.id)}
                      onCheckedChange={(checked) => onSelectTask && onSelectTask(task.id, !!checked)}
                      aria-label={`Select task ${task.summary}`}
                    />
                  </TableCell>
                )}
                <TableCell className="font-medium">{task.ticket}</TableCell>
                <TableCell>{task.summary}</TableCell>
                <TableCell>{task.project_action}</TableCell>
                <TableCell>
                  <Badge variant="outline" className="bg-green-50">
                    {task.status}
                  </Badge>
                </TableCell>
                <TableCell>
                  <Badge className={getRiskBadgeStyles(task.current_risk)}>{task.current_risk}%</Badge>
                </TableCell>
                <TableCell>{task.owner}</TableCell>
                <TableCell>{task.department}</TableCell>
                <TableCell>{formatDate(task.last_check)}</TableCell>
                <TableCell>
                  <div className="flex gap-2">
                    <Button size="sm" variant="outline" onClick={() => onEditTask(task)}>
                      <Edit className="w-4 h-4" />
                    </Button>
                    <Button size="sm" variant="outline" onClick={() => onDeleteTask(task.id)}>
                      <Trash2 className="w-4 h-4" />
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
    </div>
  )
}
[V0_FILE]typescriptreact:file="components/bulk-actions.tsx" isFixed="true" isEdit="true" isQuickEdit="true" isMerged="true"
"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog"
import { Checkbox } from "@/components/ui/checkbox"
import { Label } from "@/components/ui/label"
import { ScrollArea } from "@/components/ui/scroll-area"
import { AlertTriangle, Trash2, Edit, FileSpreadsheet, CheckSquare, Square } from "lucide-react"
import type { TaskStatus, Task } from "@/lib/types"
import ExcelJS from "exceljs"
import { getRiskLevel, getRiskColor } from "@/lib/utils"

interface BulkActionsProps {
  selectedTaskIds: string[]
  selectedTasks?: Task[]
  onDeleteTasks: () => void
  onUpdateTasksStatus: (status: TaskStatus) => void
  disabled?: boolean
}

interface ExcelColumn {
  key: string
  header: string
  width: number
}

const availableColumns: ExcelColumn[] = [
  { key: "id", header: "ID", width: 10 },
  { key: "ticket", header: "Ticket", width: 15 },
  { key: "summary", header: "Resumen", width: 40 },
  { key: "description", header: "Descripción", width: 50 },
  { key: "project_action", header: "Proyecto/Acción", width: 30 },
  { key: "status", header: "Estado", width: 20 },
  { key: "probability", header: "Probabilidad", width: 15 },
  { key: "impact", header: "Impacto", width: 15 },
  { key: "raw_risk", header: "Riesgo Inicial", width: 15 },
  { key: "current_risk", header: "Riesgo Actual", width: 15 },
  { key: "risk_level", header: "Nivel de Riesgo", width: 15 },
  { key: "owner", header: "Propietario", width: 20 },
  { key: "department", header: "Departamento", width: 20 },
  { key: "coordinator", header: "Coordinador", width: 20 },
  { key: "technician", header: "Técnico", width: 20 },
  { key: "due_date", header: "Fecha Límite", width: 15 },
  { key: "creation_date", header: "Fecha de Creación", width: 15 },
  { key: "last_check", header: "Última Revisión", width: 15 },
  { key: "completion_date", header: "Fecha de Completado", width: 15 },
  { key: "cis_control", header: "Control CIS", width: 15 },
  { key: "notes", header: "Notas", width: 40 },
  { key: "evidence", header: "Evidencia", width: 40 },
]

// Columnas esenciales que están seleccionadas por defecto
const defaultSelectedColumns = [
  "ticket",
  "summary",
  "project_action",
  "status",
  "current_risk",
  "risk_level",
  "owner",
  "department",
  "due_date",
]

const statusOptions: TaskStatus[] = [
  "Pending Ticket",
  "Pending",
  "Scheduled",
  "Request for Authorization",
  "In Progress",
  "Implementation In Progress",
  "Completed 2025",
  "Completed 2024",
  "Closed",
]

export function BulkActions({
  selectedTaskIds,
  selectedTasks = [],
  onDeleteTasks,
  onUpdateTasksStatus,
  disabled = false,
}: BulkActionsProps) {
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false)
  const [isStatusDialogOpen, setIsStatusDialogOpen] = useState(false)
  const [isExportDialogOpen, setIsExportDialogOpen] = useState(false)
  const [selectedStatus, setSelectedStatus] = useState<TaskStatus | "">("")
  const [selectedColumns, setSelectedColumns] = useState<string[]>(defaultSelectedColumns)

  const handleDeleteConfirm = () => {
    onDeleteTasks()
    setIsDeleteDialogOpen(false)
  }

  const handleStatusConfirm = () => {
    if (selectedStatus) {
      onUpdateTasksStatus(selectedStatus as TaskStatus)
      setIsStatusDialogOpen(false)
      setSelectedStatus("")
    }
  }

  // Función para convertir el color de Tailwind a código de color Excel
  const getRiskColorARGB = (risk: number): string => {
    const colorClass = getRiskColor(risk)

    if (colorClass.includes("bg-green-700")) return "FF008000"
    if (colorClass.includes("bg-green-500")) return "FF10B981"
    if (colorClass.includes("bg-lime-500")) return "FF84CC16"
    if (colorClass.includes("bg-yellow-400")) return "FFEAB308"
    if (colorClass.includes("bg-amber-500")) return "FFF59E0B"
    if (colorClass.includes("bg-orange-500")) return "FFF97316"
    if (colorClass.includes("bg-orange-600")) return "FFEA580C"
    if (colorClass.includes("bg-red-600")) return "FFDC2626"

    return "FFFFFFFF"
  }

  const getTextColorARGB = (risk: number): string => {
    const colorClass = getRiskColor(risk)
    if (colorClass.includes("bg-yellow-400")) return "FF000000"
    return "FFFFFFFF"
  }

  const handleToggleColumn = (columnKey: string) => {
    setSelectedColumns((prev) =>
      prev.includes(columnKey) ? prev.filter((key) => key !== columnKey) : [...prev, columnKey],
    )
  }

  const handleSelectAllColumns = () => {
    setSelectedColumns(availableColumns.map((col) => col.key))
  }

  const handleDeselectAllColumns = () => {
    setSelectedColumns([])
  }

  const handleExportToExcel = async () => {
    if (!selectedTasks || selectedTasks.length === 0 || selectedColumns.length === 0) return

    const workbook = new ExcelJS.Workbook()
    workbook.creator = "CyberSec Tasks"
    workbook.lastModifiedBy = "CyberSec Tasks"
    workbook.created = new Date()
    workbook.modified = new Date()

    const worksheet = workbook.addWorksheet("Tareas")

    // Definir solo las columnas seleccionadas
    const columnsToExport = availableColumns.filter((col) => selectedColumns.includes(col.key))
    worksheet.columns = columnsToExport

    // Dar formato a los encabezados
    worksheet.getRow(1).font = { bold: true }
    worksheet.getRow(1).fill = {
      type: "pattern",
      pattern: "solid",
      fgColor: { argb: "FFE0E0E0" },
    }

    // Añadir los datos
    selectedTasks.forEach((task) => {
      const rowData: any = {}

      selectedColumns.forEach((columnKey) => {
        if (columnKey === "risk_level") {
          rowData[columnKey] = getRiskLevel(task.current_risk)
        } else if (["due_date", "creation_date", "last_check", "completion_date"].includes(columnKey)) {
          // Formatear fechas para Excel
          rowData[columnKey] = task[columnKey as keyof Task] ? new Date(task[columnKey as keyof Task] as string) : null
        } else {
          rowData[columnKey] = task[columnKey as keyof Task] || ""
        }
      })

      worksheet.addRow(rowData)
    })

    // Aplicar formato de fecha a las columnas de fecha seleccionadas
    const dateColumns = ["due_date", "creation_date", "last_check", "completion_date"].filter((col) =>
      selectedColumns.includes(col),
    )
    dateColumns.forEach((dateColumn) => {
      const column = worksheet.getColumn(dateColumn)
      if (column) {
        column.numFmt = "dd/mm/yyyy"
      }
    })

    // Aplicar formato condicional a las columnas de riesgo
    worksheet.eachRow((row, rowNumber) => {
      if (rowNumber > 1) {
        // Si está seleccionada la columna de riesgo inicial
        if (selectedColumns.includes("raw_risk")) {
          const rawRiskCell = row.getCell("raw_risk")
          const rawRiskValue = rawRiskCell.value as number
          if (rawRiskValue) {
            rawRiskCell.fill = {
              type: "pattern",
              pattern: "solid",
              fgColor: { argb: getRiskColorARGB(rawRiskValue) },
            }
            rawRiskCell.font = {
              color: { argb: getTextColorARGB(rawRiskValue) },
              bold: true,
            }
          }
        }

        // Si está seleccionada la columna de riesgo actual
        if (selectedColumns.includes("current_risk")) {
          const currentRiskCell = row.getCell("current_risk")
          const currentRiskValue = currentRiskCell.value as number
          if (currentRiskValue) {
            currentRiskCell.fill = {
              type: "pattern",
              pattern: "solid",
              fgColor: { argb: getRiskColorARGB(currentRiskValue) },
            }
            currentRiskCell.font = {
              color: { argb: getTextColorARGB(currentRiskValue) },
              bold: true,
            }
          }
        }

        // Si está seleccionada la columna de nivel de riesgo
        if (selectedColumns.includes("risk_level")) {
          const riskLevelCell = row.getCell("risk_level")
          // Obtener el valor de riesgo actual para determinar el color
          const task = selectedTasks[rowNumber - 2] // -2 porque rowNumber empieza en 1 y tiene encabezado
          if (task && task.current_risk) {
            riskLevelCell.fill = {
              type: "pattern",
              pattern: "solid",
              fgColor: { argb: getRiskColorARGB(task.current_risk) },
            }
            riskLevelCell.font = {
              color: { argb: getTextColorARGB(task.current_risk) },
              bold: true,
            }
          }
        }
      }

      // Añadir bordes a todas las celdas
      row.eachCell((cell) => {
        cell.border = {
          top: { style: "thin" },
          left: { style: "thin" },
          bottom: { style: "thin" },
          right: { style: "thin" },
        }
      })
    })

    // Aplicar autofilter a todas las columnas
    if (worksheet.columns.length > 0) {
      worksheet.autoFilter = {
        from: { row: 1, column: 1 },
        to: { row: 1, column: worksheet.columns.length },
      }
    }

    // Congelar la primera fila
    worksheet.views = [{ state: "frozen", xSplit: 0, ySplit: 1, activeCell: "A2" }]

    // Generar el archivo y descargarlo
    const buffer = await workbook.xlsx.writeBuffer()
    const blob = new Blob([buffer], { type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" })
    const url = window.URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = `cybersec_tasks_export_${new Date().toISOString().split("T")[0]}.xlsx`
    a.click()
    window.URL.revokeObjectURL(url)

    setIsExportDialogOpen(false)
  }

  const selectedCount = selectedTaskIds.length

  if (selectedCount === 0) {
    return null
  }

  return (
    <div className="flex items-center gap-2 p-2 bg-gray-100 rounded-md">
      <span className="text-sm font-medium">
        {selectedCount} {selectedCount === 1 ? "tarea seleccionada" : "tareas seleccionadas"}
      </span>

      <Button
        size="sm"
        variant="outline"
        onClick={() => setIsStatusDialogOpen(true)}
        disabled={disabled}
        className="ml-2"
      >
        <Edit className="w-4 h-4 mr-1" />
        Cambiar estado
      </Button>

      <Button
        size="sm"
        variant="outline"
        onClick={() => setIsExportDialogOpen(true)}
        disabled={disabled || !selectedTasks || selectedTasks.length === 0}
        className="text-green-600 hover:text-green-800"
      >
        <FileSpreadsheet className="w-4 h-4 mr-1" />
        Exportar a Excel
      </Button>

      <Button
        size="sm"
        variant="outline"
        onClick={() => setIsDeleteDialogOpen(true)}
        disabled={disabled}
        className="text-red-500 hover:text-red-700"
      >
        <Trash2 className="w-4 h-4 mr-1" />
        Eliminar
      </Button>

      {/* Diálogo de confirmación para eliminar */}
      <Dialog open={isDeleteDialogOpen} onOpenChange={setIsDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center">
              <AlertTriangle className="w-5 h-5 text-red-500 mr-2" />
              Confirmar eliminación
            </DialogTitle>
          </DialogHeader>
          <div className="py-4">
            <p>
              ¿Estás seguro de que deseas eliminar {selectedCount} {selectedCount === 1 ? "tarea" : "tareas"}?
            </p>
            <p className="text-red-500 text-sm mt-2">Esta acción no se puede deshacer.</p>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDeleteDialogOpen(false)}>
              Cancelar
            </Button>
            <Button variant="destructive" onClick={handleDeleteConfirm}>
              Eliminar
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Diálogo para cambiar estado */}
      <Dialog open={isStatusDialogOpen} onOpenChange={setIsStatusDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Cambiar estado de tareas</DialogTitle>
          </DialogHeader>
          <div className="py-4">
            <p className="mb-4">
              Selecciona el nuevo estado para {selectedCount} {selectedCount === 1 ? "tarea" : "tareas"}:
            </p>
            <Select value={selectedStatus} onValueChange={(value) => setSelectedStatus(value as TaskStatus)}>
              <SelectTrigger>
                <SelectValue placeholder="Seleccionar estado" />
              </SelectTrigger>
              <SelectContent>
                {statusOptions.map((status) => (
                  <SelectItem key={status} value={status}>
                    {status}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsStatusDialogOpen(false)}>
              Cancelar
            </Button>
            <Button onClick={handleStatusConfirm} disabled={!selectedStatus}>
              Actualizar
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Diálogo para exportar a Excel */}
      <Dialog open={isExportDialogOpen} onOpenChange={setIsExportDialogOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Exportar a Excel - Seleccionar columnas</DialogTitle>
          </DialogHeader>
          <div className="py-4">
            <div className="flex justify-between items-center mb-4">
              <p className="text-sm text-gray-600">Selecciona las columnas que deseas incluir en la exportación</p>
              <div className="flex gap-2">
                <Button size="sm" variant="outline" onClick={handleSelectAllColumns} className="text-xs">
                  <CheckSquare className="w-3 h-3 mr-1" />
                  Seleccionar todas
                </Button>
                <Button size="sm" variant="outline" onClick={handleDeselectAllColumns} className="text-xs">
                  <Square className="w-3 h-3 mr-1" />
                  Deseleccionar todas
                </Button>
              </div>
            </div>
            <ScrollArea className="h-[400px] pr-4">
              <div className="grid grid-cols-2 gap-3">
                {availableColumns.map((column) => (
                  <div key={column.key} className="flex items-center space-x-2">
                    <Checkbox
                      id={column.key}
                      checked={selectedColumns.includes(column.key)}
                      onCheckedChange={() => handleToggleColumn(column.key)}
                    />
                    <Label htmlFor={column.key} className="text-sm cursor-pointer select-none flex-1">
                      {column.header}
                    </Label>
                  </div>
                ))}
              </div>
            </ScrollArea>
            <div className="mt-4 text-sm text-gray-600">{selectedColumns.length} columnas seleccionadas</div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsExportDialogOpen(false)}>
              Cancelar
            </Button>
            <Button
              onClick={handleExportToExcel}
              disabled={selectedColumns.length === 0}
              className="bg-green-600 hover:bg-green-700 text-white"
            >
              <FileSpreadsheet className="w-4 h-4 mr-1" />
              Exportar
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
[V0_FILE]typescript:file="app/api/tasks/bulk/route.ts" isEdit="true" isMerged="true"
import { type NextRequest, NextResponse } from "next/server"
import { sql } from "@/lib/db"

export async function DELETE(request: NextRequest) {
  try {
    const { ids } = await request.json()

    if (!Array.isArray(ids) || ids.length === 0) {
      return NextResponse.json({ error: "Invalid or empty task IDs array" }, { status: 400 })
    }

    // Imprimir los IDs que estamos intentando eliminar para depuración
    console.log("Attempting to delete tasks with IDs:", ids)

    // Usar consulta parametrizada para mayor seguridad
    // Crear placeholders para cada ID ($1, $2, etc.)
    const placeholders = ids.map((_, i) => `$${i + 1}`).join(", ")

    // Ejecutar la consulta con los IDs como parámetros
    const query = `DELETE FROM tasks WHERE id IN (${placeholders}) RETURNING id`
    const result = await sql.query(query, ids)

    // Verificar el resultado y registrar información para depuración
    console.log("Delete result structure:", Object.keys(result))
    console.log("Delete result rowCount:", result.rowCount)
    console.log("Delete result rows:", result.rows)

    // Contar manualmente las filas eliminadas para asegurarnos
    const deletedCount = result.rows ? result.rows.length : 0
    console.log("Manually counted deleted rows:", deletedCount)

    // Devolver una respuesta clara con el número de tareas eliminadas
    return NextResponse.json({
      success: true,
      deletedCount: deletedCount,
      deletedIds: result.rows ? result.rows.map((row) => row.id) : [],
    })
  } catch (error) {
    console.error("Error deleting tasks in bulk:", error)
    return NextResponse.json({ error: `Failed to delete tasks: ${error.message || String(error)}` }, { status: 500 })
  }
}

export async function PATCH(request: NextRequest) {
  try {
    const { ids, status } = await request.json()

    if (!Array.isArray(ids) || ids.length === 0) {
      return NextResponse.json({ error: "Invalid or empty task IDs array" }, { status: 400 })
    }

    if (!status) {
      return NextResponse.json({ error: "Status is required" }, { status: 400 })
    }

    // Actualizar el estado de las tareas en bulk usando consulta parametrizada
    const now = new Date().toISOString().split("T")[0]
    const completion_date = status.startsWith("Completed") || status === "Closed" ? now : null

    // Crear placeholders para cada ID
    const placeholders = ids.map((_, i) => `$${i + 3}`).join(", ")

    // Ejecutar la consulta con los parámetros
    const query = `
      UPDATE tasks 
      SET 
        status = $1, 
        last_check = $2,
        completion_date = ${completion_date ? "$3" : "NULL"},
        updated_at = CURRENT_TIMESTAMP
      WHERE id IN (${placeholders})
      RETURNING id, status
    `

    const params = completion_date ? [status, now, completion_date, ...ids] : [status, now, ...ids]

    const result = await sql.query(query, params)

    // Verificar el resultado y registrar información para depuración
    console.log("Update result structure:", Object.keys(result))
    console.log("Update result rowCount:", result.rowCount)
    console.log("Update result rows:", result.rows)

    // Contar manualmente las filas actualizadas para asegurarnos
    const updatedCount = result.rows ? result.rows.length : 0
    console.log("Manually counted updated rows:", updatedCount)

    return NextResponse.json({
      success: true,
      updatedCount: updatedCount,
      updatedIds: result.rows ? result.rows.map((row) => row.id) : [],
    })
  } catch (error) {
    console.error("Error updating tasks in bulk:", error)
    return NextResponse.json({ error: `Failed to update tasks: ${error.message || String(error)}` }, { status: 500 })
  }
}
[V0_FILE]typescript:file="app/page.tsx" isFixed="true" isEdit="true" isQuickEdit="true" isMerged="true"
"use client"

import { useState, useEffect } from "react"
import type { Task, TaskFilters, ViewMode, TaskStatus } from "@/lib/types"
import { TaskForm } from "@/components/task-form"
import { TaskKanban } from "@/components/task-kanban"
import { TaskTable } from "@/components/task-table"
import { CompletedTasksTable } from "@/components/completed-tasks-table"
import { TaskFilters as TaskFiltersComponent } from "@/components/task-filters"
import { BulkActions } from "@/components/bulk-actions"
import { Dashboard } from "@/components/dashboard/dashboard"
import { PersonnelManagement } from "@/components/personnel-management"
import { Badge } from "@/components/ui/badge"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { getRiskLevel } from "@/lib/utils"
import { LayoutGrid, Table, Shield, CheckCircle, AlertTriangle, BarChart3, Users } from "lucide-react"
import { useToast } from "@/components/ui/use-toast"
import { api } from "@/lib/api"
import { Button } from "@/components/ui/button"

export default function Home() {
  const [tasks, setTasks] = useState<Task[]>([])
  const [filteredTasks, setFilteredTasks] = useState<Task[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [viewMode, setViewMode] = useState<ViewMode>("kanban")
  const [isFormOpen, setIsFormOpen] = useState(false)
  const [editingTask, setEditingTask] = useState<Task | undefined>()
  const [selectedTaskIds, setSelectedTaskIds] = useState<string[]>([])
  const [activeTab, setActiveTab] = useState("dashboard")
  const [filters, setFilters] = useState<TaskFilters>({
    search: "",
    status: "All",
    department: "",
    owner: "",
    riskLevel: "All",
  })
  const { toast } = useToast()
  const [personnelUpdated, setPersonnelUpdated] = useState(0)

  useEffect(() => {
    initializeApp()
  }, [])

  useEffect(() => {
    applyFilters()
  }, [tasks, filters])

  // Limpiar selección al cambiar de pestaña
  useEffect(() => {
    setSelectedTaskIds([])
  }, [activeTab])

  const initializeApp = async () => {
    try {
      setLoading(true)
      setError(null)

      // Inicializar base de datos si es necesario
      const initResult = await api.initialize()
      console.log("Initialization result:", initResult)

      // Cargar tareas
      await fetchTasks()

      toast({
        title: "Aplicación inicializada",
        description: "Conectado al servidor correctamente.",
      })
    } catch (error) {
      console.error("Error initializing app:", error)
      setError(error instanceof Error ? error.message : "Error desconocido al inicializar la aplicación")
      toast({
        title: "Error",
        description: "Error al inicializar la aplicación. Consulta la consola para más detalles.",
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  const fetchTasks = async () => {
    try {
      const data = await api.getTasks()
      setTasks(data.all || [])
    } catch (error) {
      console.error("Error fetching tasks:", error)
      toast({
        title: "Error",
        description: "Error al cargar las tareas. Por favor, recarga la página.",
        variant: "destructive",
      })
    }
  }

  const applyFilters = () => {
    let filtered = tasks

    if (filters.search) {
      filtered = filtered.filter(
        (task) =>
          task.summary?.toLowerCase().includes(filters.search.toLowerCase()) ||
          (task.ticket && task.ticket.toLowerCase().includes(filters.search.toLowerCase())) ||
          task.project_action?.toLowerCase().includes(filters.search.toLowerCase()),
      )
    }

    if (filters.status !== "All") {
      filtered = filtered.filter((task) => task.status === filters.status)
    }

    if (filters.department) {
      filtered = filtered.filter((task) => task.department?.toLowerCase().includes(filters.department.toLowerCase()))
    }

    if (filters.owner) {
      filtered = filtered.filter((task) => task.owner?.toLowerCase().includes(filters.owner.toLowerCase()))
    }

    if (filters.riskLevel !== "All") {
      filtered = filtered.filter((task) => getRiskLevel(task.current_risk) === filters.riskLevel)
    }

    setFilteredTasks(filtered)
  }

  const handleCreateTask = async (taskData: Partial<Task>) => {
    try {
      await api.createTask(taskData)
      // Cerrar el formulario
      setIsFormOpen(false)
      // Recargar las tareas
      await fetchTasks()
      toast({
        title: "Tarea creada",
        description: "La tarea se ha creado correctamente.",
      })
    } catch (error) {
      console.error("Error creating task:", error)
      toast({
        title: "Error",
        description: "Error al crear la tarea. Por favor, inténtalo de nuevo.",
        variant: "destructive",
      })
    }
  }

  const handleUpdateTask = async (taskData: Partial<Task>) => {
    if (!editingTask) return

    try {
      await api.updateTask(editingTask.id, { ...editingTask, ...taskData })
      // Cerrar el formulario antes de recargar las tareas
      setEditingTask(undefined)
      setIsFormOpen(false)

      // Recargar las tareas
      await fetchTasks()
      toast({
        title: "Tarea actualizada",
        description: "La tarea se ha actualizado correctamente.",
      })
    } catch (error) {
      console.error("Error updating task:", error)
      toast({
        title: "Error",
        description: "Error al actualizar la tarea. Por favor, inténtalo de nuevo.",
        variant: "destructive",
      })
    }
  }

  const handleDeleteTask = async (id: string) => {
    if (!confirm("Are you sure you want to delete this task?")) return

    try {
      await api.deleteTask(id)
      await fetchTasks()
      toast({
        title: "Tarea eliminada",
        description: "La tarea se ha eliminado correctamente.",
      })
    } catch (error) {
      console.error("Error deleting task:", error)
      toast({
        title: "Error",
        description: "Error al eliminar la tarea. Por favor, inténtalo de nuevo.",
        variant: "destructive",
      })
    }
  }

  const handleEditTask = (task: Task) => {
    setEditingTask(task)
    setIsFormOpen(true)
  }

  const handleExport = async (format: "json" | "csv") => {
    try {
      const blob = await api.exportTasks(format)
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement("a")
      a.href = url
      a.download = `cybersec_tasks.${format}`
      a.click()
      window.URL.revokeObjectURL(url)
      toast({
        title: "Exportación completada",
        description: `Las tareas se han exportado correctamente en formato ${format.toUpperCase()}.`,
      })
    } catch (error) {
      console.error("Error exporting tasks:", error)
      toast({
        title: "Error",
        description: "Error al exportar las tareas. Por favor, inténtalo de nuevo.",
        variant: "destructive",
      })
    }
  }

  const handleImport = async (file: File) => {
    try {
      setLoading(true) // Mostrar indicador de carga

      const text = await file.text()
      let importedData

      try {
        importedData = JSON.parse(text)
      } catch (error) {
        console.error("Error parsing JSON:", error)
        toast({
          title: "Error",
          description: "El archivo no contiene JSON válido. Por favor, verifica el formato.",
          variant: "destructive",
        })
        setLoading(false)
        return
      }

      console.log("Datos importados:", importedData)

      // Verificar si es un backup completo o solo tareas
      if (importedData.data) {
        // Es un backup completo, restaurar todo
        try {
          const response = await fetch("/api/backup", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(importedData),
          })

          if (response.ok) {
            await fetchTasks()
            toast({
              title: "Backup restaurado",
              description: "El backup se ha restaurado correctamente. Verifica las tareas en las diferentes pestañas.",
            })
          } else {
            const errorData = await response.json()
            console.error("Error en la respuesta del servidor:", errorData)
            toast({
              title: "Error",
              description: `Error al restaurar el backup: ${errorData.error || "Error desconocido"}`,
              variant: "destructive",
            })
          }
        } catch (error) {
          console.error("Error al restaurar el backup:", error)
          toast({
            title: "Error",
            description: `Error al restaurar el backup: ${error}`,
            variant: "destructive",
          })
        }
      } else if (Array.isArray(importedData)) {
        // Es un array de tareas, importar una por una
        let successCount = 0
        let errorCount = 0

        for (const task of importedData) {
          try {
            const response = await fetch("/api/tasks", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify(task),
            })

            if (response.ok) {
              successCount++
            } else {
              errorCount++
              const errorData = await response.json()
              console.error(`Error al importar tarea ${task.summary || "sin título"}:`, errorData)
            }
          } catch (error) {
            errorCount++
            console.error(`Error al importar tarea ${task.summary || "sin título"}:`, error)
          }
        }

        await fetchTasks()

        if (errorCount === 0) {
          toast({
            title: "Importación completada",
            description: `Se importaron ${successCount} tareas correctamente. Verifica las tareas en las diferentes pestañas.`,
          })
        } else {
          toast({
            title: "Importación parcial",
            description: `Se importaron ${successCount} tareas correctamente, pero hubo ${errorCount} errores. Revisa la consola para más detalles.`,
            variant: "destructive",
          })
        }
      } else {
        toast({
          title: "Error",
          description: "Formato de archivo no reconocido. Debe ser un array de tareas o un backup completo.",
          variant: "destructive",
        })
      }
    } catch (error) {
      console.error("Error general al importar:", error)
      toast({
        title: "Error",
        description: `Error al importar: ${error}`,
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  const getTaskStats = () => {
    const total = tasks.length
    const inProgress = tasks.filter((t) => t.status === "In Progress").length
    const completed2025 = tasks.filter((t) => t.status === "Completed 2025").length
    const completed2024 = tasks.filter((t) => t.status === "Completed 2024").length
    const closed = tasks.filter((t) => t.status === "Closed").length
    const highRisk = tasks.filter(
      (t) => getRiskLevel(t.current_risk) === "High" || getRiskLevel(t.current_risk) === "Critical",
    ).length

    return { total, inProgress, completed2025, completed2024, closed, highRisk }
  }

  const stats = getTaskStats()

  const handlePreviewImport = (tasks: Task[]) => {
    console.log("Vista previa de importación:", tasks)
    // Esta función se llama desde el componente ImportPreview
    // pero la importación real se hace en handleImport
  }

  const handleBackup = async () => {
    try {
      const blob = await api.exportTasks("json")
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement("a")
      a.href = url
      a.download = `cybersec_backup_${new Date().toISOString().split("T")[0]}.json`
      a.click()
      window.URL.revokeObjectURL(url)
      toast({
        title: "Backup creado",
        description: "El backup se ha creado correctamente.",
      })
    } catch (error) {
      console.error("Error creating backup:", error)
      toast({
        title: "Error",
        description: "Error al crear el backup. Por favor, inténtalo de nuevo.",
        variant: "destructive",
      })
    }
  }

  // Funciones para la gestión en bulk
  const handleSelectTask = (id: string, selected: boolean) => {
    if (selected) {
      setSelectedTaskIds((prev) => [...prev, id])
    } else {
      setSelectedTaskIds((prev) => prev.filter((taskId) => taskId !== id))
    }
  }

  const handleBulkDelete = async () => {
    if (selectedTaskIds.length === 0) {
      toast({
        title: "Error",
        description: "No hay tareas seleccionadas para eliminar.",
        variant: "destructive",
      })
      return
    }

    if (!confirm(`¿Estás seguro de que deseas eliminar ${selectedTaskIds.length} tareas?`)) {
      return
    }

    try {
      setLoading(true)
      console.log("Deleting tasks with IDs:", selectedTaskIds)

      const result = await api.bulkDeleteTasks(selectedTaskIds)
      console.log("Bulk delete result in handleBulkDelete:", result)

      // Verificar explícitamente la estructura del resultado
      const deletedCount = typeof result.deletedCount === "number" ? result.deletedCount : selectedTaskIds.length // Fallback: asumir que todas las tareas se eliminaron

      await fetchTasks()
      setSelectedTaskIds([])

      toast({
        title: "Tareas eliminadas",
        description: `Se han eliminado ${deletedCount} tareas correctamente.`,
      })
    } catch (error) {
      console.error("Error deleting tasks in bulk:", error)
      toast({
        title: "Error",
        description: `Error al eliminar las tareas: ${error.message || "Error desconocido"}`,
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  const handleBulkUpdateStatus = async (status: TaskStatus) => {
    try {
      setLoading(true)
      const result = await api.bulkUpdateTaskStatus(selectedTaskIds, status)

      await fetchTasks()
      setSelectedTaskIds([])

      toast({
        title: "Estado actualizado",
        description: `Se ha actualizado el estado de ${result.updatedCount} tareas a "${status}".`,
      })
    } catch (error) {
      console.error("Error updating tasks status in bulk:", error)
      toast({
        title: "Error",
        description: "Error al actualizar el estado de las tareas. Por favor, inténtalo de nuevo.",
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  // Manejar la actualización de personal
  const handlePersonnelUpdate = () => {
    // Incrementar el contador para forzar la actualización
    setPersonnelUpdated((prev) => prev + 1)

    // Forzar la apertura del formulario para actualizar las listas
    if (isFormOpen) {
      setIsFormOpen(false)
      setTimeout(() => setIsFormOpen(true), 100)
    }
  }

  // Añadir esta función para obtener las tareas seleccionadas completas
  const getSelectedTasks = () => {
    return tasks.filter((task) => selectedTaskIds.includes(task.id))
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-gray-900"></div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen p-4">
        <div className="bg-red-50 border border-red-200 rounded-lg p-6 max-w-lg w-full text-center">
          <AlertTriangle className="w-12 h-12 text-red-500 mx-auto mb-4" />
          <h2 className="text-xl font-bold text-red-700 mb-2">Error de inicialización</h2>
          <p className="text-red-600 mb-4">{error}</p>
          <Button onClick={() => initializeApp()}>Reintentar</Button>
        </div>
      </div>
    )
  }

  // Filtrar tareas activas (no completadas)
  const activeTasks = filteredTasks.filter((task) => !task.status.startsWith("Completed") && task.status !== "Closed")

  // Determinar si mostrar las acciones en bulk (solo en vistas de tabla)
  const showBulkActions =
    activeTab !== "kanban" && activeTab !== "dashboard" && activeTab !== "personnel" && selectedTaskIds.length > 0

  // Solo mostrar filtros en pestañas relacionadas con tareas
  const showFilters = activeTab !== "personnel"

  return (
    <div className="container mx-auto p-6">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-4">
          <Shield className="w-8 h-8 text-blue-600" />
          <h1 className="text-3xl font-bold">Cybersecurity Task Management</h1>
        </div>
        <div className="flex items-center gap-4">
          <div className="flex gap-2">
            <Badge variant="outline">Total: {stats.total}</Badge>
            <Badge variant="outline">In Progress: {stats.inProgress}</Badge>
            <Badge variant="outline" className="bg-green-50">
              Completed 2025: {stats.completed2025}
            </Badge>
            <Badge variant="outline" className="bg-green-50">
              Completed 2024: {stats.completed2024}
            </Badge>
            <Badge variant="outline">Closed: {stats.closed}</Badge>
            <Badge className="bg-red-100 text-red-600">High Risk: {stats.highRisk}</Badge>
          </div>
          <TaskForm
            task={editingTask}
            onSubmit={editingTask ? handleUpdateTask : handleCreateTask}
            onCancel={() => {
              setEditingTask(undefined)
              setIsFormOpen(false)
            }}
            isOpen={isFormOpen}
            setIsOpen={setIsFormOpen}
          />
        </div>
      </div>

      {showFilters && (
        <TaskFiltersComponent
          filters={filters}
          onFiltersChange={setFilters}
          onExport={handleExport}
          onImport={handleImport}
          onPreviewImport={handlePreviewImport}
          onBackup={handleBackup}
          tasks={tasks}
        />
      )}

      {/* Acciones en bulk - Solo mostrar en vistas de tabla */}
      {showBulkActions && (
        <div className="mt-4">
          <BulkActions
            selectedTaskIds={selectedTaskIds}
            selectedTasks={getSelectedTasks()}
            onDeleteTasks={handleBulkDelete}
            onUpdateTasksStatus={handleBulkUpdateStatus}
            disabled={loading}
          />
        </div>
      )}

      <div className="mt-6">
        <Tabs defaultValue="dashboard" onValueChange={setActiveTab}>
          <TabsList className="mb-4">
            <TabsTrigger value="dashboard">
              <BarChart3 className="w-4 h-4 mr-2" />
              Dashboard
            </TabsTrigger>
            <TabsTrigger value="kanban">
              <LayoutGrid className="w-4 h-4 mr-2" />
              Active Tasks
            </TabsTrigger>
            <TabsTrigger value="table">
              <Table className="w-4 h-4 mr-2" />
              Table View
            </TabsTrigger>
            <TabsTrigger value="completed-2025">
              <CheckCircle className="w-4 h-4 mr-2" />
              Completed 2025
            </TabsTrigger>
            <TabsTrigger value="completed-2024">
              <CheckCircle className="w-4 h-4 mr-2" />
              Completed 2024
            </TabsTrigger>
            <TabsTrigger value="personnel">
              <Users className="w-4 h-4 mr-2" />
              Personnel
            </TabsTrigger>
          </TabsList>

          <TabsContent value="dashboard">
            <Dashboard tasks={filteredTasks} />
          </TabsContent>

          <TabsContent value="kanban">
            <TaskKanban tasks={filteredTasks} onEditTask={handleEditTask} onDeleteTask={handleDeleteTask} />
          </TabsContent>

          <TabsContent value="table">
            <TaskTable
              tasks={activeTasks}
              onEditTask={handleEditTask}
              onDeleteTask={handleDeleteTask}
              selectedTaskIds={selectedTaskIds}
              onSelectTask={handleSelectTask}
            />
          </TabsContent>

          <TabsContent value="completed-2025">
            <CompletedTasksTable
              tasks={filteredTasks}
              year="2025"
              onEditTask={handleEditTask}
              onDeleteTask={handleDeleteTask}
              selectedTaskIds={selectedTaskIds}
              onSelectTask={handleSelectTask}
            />
          </TabsContent>

          <TabsContent value="completed-2024">
            <CompletedTasksTable
              tasks={filteredTasks}
              year="2024"
              onEditTask={handleEditTask}
              onDeleteTask={handleDeleteTask}
              selectedTaskIds={selectedTaskIds}
              onSelectTask={handleSelectTask}
            />
          </TabsContent>

          <TabsContent value="personnel">
            <PersonnelManagement onPersonnelUpdate={handlePersonnelUpdate} />
          </TabsContent>
        </Tabs>
      </div>
    </div>
  )
}
[V0_FILE]typescript:file="app/api/tasks/sample/route.ts" isEdit="true" isMerged="true"
import { NextResponse } from "next/server"
import { sql } from "@/lib/db"
import { format } from "date-fns"

export async function GET() {
  try {
    // Generar 10 tareas de ejemplo
    const tasks = []
    const departments = ["Seguridad", "Infraestructura", "Operaciones"]
    const owners = ["Juan Pérez", "María López", "Carlos Rodríguez"]
    const coordinators = ["Ana Martínez", "Pedro Sánchez", "Laura García"]
    const technicians = ["Roberto Fernández", "Sofía Díaz", "Miguel Álvarez"]
    const statuses = ["Pending", "In Progress", "Scheduled", "Request for Authorization"]

    for (let i = 1; i <= 10; i++) {
      const rawProbability = Math.floor(Math.random() * 100)
      const rawImpact = Math.floor(Math.random() * 100)
      const rawRisk = Math.floor((rawProbability + rawImpact) / 2)

      const treatedProbability = Math.floor(rawProbability * 0.7)
      const treatedImpact = Math.floor(rawImpact * 0.7)
      const currentRisk = Math.floor((treatedProbability + treatedImpact) / 2)

      // Generar fecha aleatoria en los últimos 30 días
      const today = new Date()
      const thirtyDaysAgo = new Date(today)
      thirtyDaysAgo.setDate(today.getDate() - 30)
      const randomDate = new Date(thirtyDaysAgo.getTime() + Math.random() * (today.getTime() - thirtyDaysAgo.getTime()))

      // Generar fecha de revisión aleatoria en los próximos 90 días
      const ninetyDaysLater = new Date(today)
      ninetyDaysLater.setDate(today.getDate() + 90)
      const randomReviewDate = new Date(today.getTime() + Math.random() * (ninetyDaysLater.getTime() - today.getTime()))

      const task = {
        ticket: `CRQ${Math.floor(Math.random() * 1000000)
          .toString()
          .padStart(6, "0")}`,
        cis_control: Math.floor(Math.random() * 18) + 1,
        project_action: `Acción de ejemplo ${i}`,
        summary: `Tarea de ejemplo ${i}`,
        description: `Esta es una descripción detallada para la tarea de ejemplo ${i}. Incluye información relevante sobre la tarea.`,
        risk: `Riesgo de ejemplo ${i}`,
        impact: `Impacto de ejemplo ${i}`,
        raw_probability: rawProbability,
        raw_impact: rawImpact,
        raw_risk: rawRisk,
        avoid: Math.random() > 0.5 ? 1 : 0,
        mitigate: Math.random() > 0.5 ? 1 : 0,
        transfer: Math.random() > 0.5 ? 1 : 0,
        accept: Math.random() > 0.5 ? 1 : null,
        treatment: `Tratamiento para la tarea de ejemplo ${i}`,
        treated_probability: treatedProbability,
        treated_impact: treatedImpact,
        current_risk: currentRisk,
        next_review: format(randomReviewDate, "yyyy-MM-dd"),
        department: departments[Math.floor(Math.random() * departments.length)],
        owner: owners[Math.floor(Math.random() * owners.length)],
        coordinator: coordinators[Math.floor(Math.random() * coordinators.length)],
        technician: technicians[Math.floor(Math.random() * technicians.length)],
        status: statuses[Math.floor(Math.random() * statuses.length)],
        last_check: format(randomDate, "yyyy-MM-dd"),
        comments: `Comentarios para la tarea de ejemplo ${i}`,
      }

      tasks.push(task)
    }

    // Insertar las tareas en la base de datos
    for (const task of tasks) {
      await sql`
        INSERT INTO tasks (
          ticket, cis_control, project_action, summary, description, 
          risk, impact, raw_probability, raw_impact, raw_risk, 
          avoid, mitigate, transfer, accept, treatment, 
          treated_probability, treated_impact, current_risk, next_review, 
          department, owner, coordinator, technician, status, last_check, comments
        ) VALUES (
          ${task.ticket}, ${task.cis_control}, ${task.project_action}, ${task.summary}, ${task.description},
          ${task.risk}, ${task.impact}, ${task.raw_probability}, ${task.raw_impact}, ${task.raw_risk},
          ${task.avoid}, ${task.mitigate}, ${task.transfer}, ${task.accept}, ${task.treatment},
          ${task.treated_probability}, ${task.treated_impact}, ${task.current_risk}, ${task.next_review},
          ${task.department}, ${task.owner}, ${task.coordinator}, ${task.technician}, ${task.status}, ${task.last_check}, ${task.comments}
        )
      `
    }

    return NextResponse.json({
      success: true,
      message: `Se han añadido ${tasks.length} tareas de ejemplo correctamente.`,
      count: tasks.length,
    })
  } catch (error) {
    console.error("Error adding sample tasks:", error)
    return NextResponse.json({ success: false, error: "Error al añadir tareas de ejemplo" }, { status: 500 })
  }
}
[V0_FILE]typescriptreact:file="components/task-filters.tsx" isEdit="true" isMerged="true"
"use client"

import type React from "react"

import { useState, useEffect } from "react"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Search, X, Download, Upload, Save } from "lucide-react"
import { api } from "@/lib/api"
import type { Task } from "@/lib/types"

interface TaskFiltersProps {
  filters?: {
    search: string
    status: string | "All"
    department: string
    owner: string
    riskLevel: string | "All"
  }
  onFiltersChange?: (filters: any) => void
  onFilterChange?: (filters: any) => void
  onExport?: (format: "json" | "csv") => void
  onImport?: (file: File) => void
  onPreviewImport?: (tasks: Task[]) => void
  onBackup?: () => void
  tasks?: Task[]
}

export function TaskFilters({
  filters = {
    search: "",
    status: "All",
    department: "",
    owner: "",
    riskLevel: "All",
  },
  onFiltersChange,
  onFilterChange,
  onExport,
  onImport,
  onPreviewImport,
  onBackup,
  tasks = [],
}: TaskFiltersProps) {
  const [departments, setDepartments] = useState<string[]>([])
  const [owners, setOwners] = useState<string[]>([])
  const [localFilters, setLocalFilters] = useState({
    status: [] as string[],
    risk: [] as string[],
    department: [] as string[],
    owner: [] as string[],
    search: "",
  })

  // Cargar lista de propietarios
  useEffect(() => {
    const fetchPersonnel = async () => {
      try {
        const data = await api.getPersonnel()
        if (data && data.owners) {
          setOwners(data.owners)
        }
      } catch (error) {
        console.error("Error fetching personnel:", error)
      }
    }

    fetchPersonnel()
  }, [])

  // Extraer departamentos únicos de las tareas
  useEffect(() => {
    if (tasks && tasks.length > 0) {
      const uniqueDepartments = Array.from(
        new Set(tasks.map((task) => task.department).filter(Boolean)),
      ).sort() as string[]
      setDepartments(uniqueDepartments)
    }
  }, [tasks])

  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newSearch = e.target.value

    // Si estamos usando la interfaz antigua
    if (onFiltersChange) {
      onFiltersChange({ ...filters, search: newSearch })
    }

    // Si estamos usando la nueva interfaz
    if (onFilterChange) {
      setLocalFilters((prev) => ({ ...prev, search: newSearch }))
      onFilterChange({ ...localFilters, search: newSearch })
    }
  }

  const handleStatusChange = (value: string) => {
    // Si estamos usando la interfaz antigua
    if (onFiltersChange) {
      onFiltersChange({ ...filters, status: value })
    }

    // Si estamos usando la nueva interfaz
    if (onFilterChange) {
      const newStatus = value === "all" ? [] : [value]
      setLocalFilters((prev) => ({ ...prev, status: newStatus }))
      onFilterChange({ ...localFilters, status: newStatus })
    }
  }

  const handleDepartmentChange = (value: string) => {
    // Si estamos usando la interfaz antigua
    if (onFiltersChange) {
      onFiltersChange({ ...filters, department: value === "all" ? "" : value })
    }

    // Si estamos usando la nueva interfaz
    if (onFilterChange) {
      const newDepartment = value === "all" ? [] : [value]
      setLocalFilters((prev) => ({ ...prev, department: newDepartment }))
      onFilterChange({ ...localFilters, department: newDepartment })
    }
  }

  const handleOwnerChange = (value: string) => {
    // Si estamos usando la interfaz antigua
    if (onFiltersChange) {
      onFiltersChange({ ...filters, owner: value === "all" ? "" : value })
    }

    // Si estamos usando la nueva interfaz
    if (onFilterChange) {
      const newOwner = value === "all" ? [] : [value]
      setLocalFilters((prev) => ({ ...prev, owner: newOwner }))
      onFilterChange({ ...localFilters, owner: newOwner })
    }
  }

  const handleRiskChange = (value: string) => {
    // Si estamos usando la interfaz antigua
    if (onFiltersChange) {
      onFiltersChange({ ...filters, riskLevel: value })
    }

    // Si estamos usando la nueva interfaz
    if (onFilterChange) {
      const newRisk = value === "all" ? [] : [value]
      setLocalFilters((prev) => ({ ...prev, risk: newRisk }))
      onFilterChange({ ...localFilters, risk: newRisk })
    }
  }

  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file && onImport) {
      onImport(file)
    }
    // Limpiar el input para permitir seleccionar el mismo archivo nuevamente
    event.target.value = ""
  }

  const resetFilters = () => {
    // Si estamos usando la interfaz antigua
    if (onFiltersChange) {
      onFiltersChange({
        search: "",
        status: "All",
        department: "",
        owner: "",
        riskLevel: "All",
      })
    }

    // Si estamos usando la nueva interfaz
    if (onFilterChange) {
      const resetFilters = {
        status: [],
        risk: [],
        department: [],
        owner: [],
        search: "",
      }
      setLocalFilters(resetFilters)
      onFilterChange(resetFilters)
    }
  }

  return (
    <div className="bg-gray-50 p-4 rounded-lg mb-6">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4 mb-4">
        <div className="relative">
          <Search className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
          <Input
            placeholder="Buscar tareas..."
            value={onFilterChange ? localFilters.search : filters.search}
            onChange={handleSearchChange}
            className="pl-10"
          />
        </div>

        <Select
          value={onFilterChange ? (localFilters.status.length > 0 ? localFilters.status[0] : "all") : filters.status}
          onValueChange={handleStatusChange}
        >
          <SelectTrigger>
            <SelectValue placeholder="Estado" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Todos los estados</SelectItem>
            <SelectItem value="Pending Ticket">Pendiente de Ticket</SelectItem>
            <SelectItem value="Pending">Pendiente</SelectItem>
            <SelectItem value="Scheduled">Programada</SelectItem>
            <SelectItem value="Request for Authorization">Solicitud de Autorización</SelectItem>
            <SelectItem value="In Progress">En Progreso</SelectItem>
            <SelectItem value="Implementation In Progress">Implementación en Progreso</SelectItem>
            <SelectItem value="Completed 2025">Completada 2025</SelectItem>
            <SelectItem value="Completed 2024">Completada 2024</SelectItem>
            <SelectItem value="Closed">Cerrada</SelectItem>
          </SelectContent>
        </Select>

        <Select
          value={
            onFilterChange
              ? localFilters.department.length > 0
                ? localFilters.department[0]
                : "all"
              : filters.department || "all"
          }
          onValueChange={handleDepartmentChange}
        >
          <SelectTrigger>
            <SelectValue placeholder="Departamento" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Todos los departamentos</SelectItem>
            {departments.map((dept) => (
              <SelectItem key={dept} value={dept}>
                {dept}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        <Select
          value={
            onFilterChange ? (localFilters.owner.length > 0 ? localFilters.owner[0] : "all") : filters.owner || "all"
          }
          onValueChange={handleOwnerChange}
        >
          <SelectTrigger>
            <SelectValue placeholder="Propietario" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Todos los propietarios</SelectItem>
            {owners.map((owner) => (
              <SelectItem key={owner} value={owner}>
                {owner}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        <Select
          value={onFilterChange ? (localFilters.risk.length > 0 ? localFilters.risk[0] : "all") : filters.riskLevel}
          onValueChange={handleRiskChange}
        >
          <SelectTrigger>
            <SelectValue placeholder="Nivel de Riesgo" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Todos los niveles</SelectItem>
            <SelectItem value="low">Bajo (0-25%)</SelectItem>
            <SelectItem value="medium">Medio (25-50%)</SelectItem>
            <SelectItem value="high">Alto (50-75%)</SelectItem>
            <SelectItem value="critical">Crítico (75-100%)</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <div className="flex flex-wrap gap-2">
        <Button variant="outline" onClick={resetFilters}>
          <X className="mr-2 h-4 w-4" />
          Limpiar Filtros
        </Button>

        {onExport && (
          <>
            <Button variant="outline" onClick={() => onExport("json")}>
              <Download className="mr-2 h-4 w-4" />
              Exportar JSON
            </Button>
            <Button variant="outline" onClick={() => onExport("csv")}>
              <Download className="mr-2 h-4 w-4" />
              Exportar CSV
            </Button>
          </>
        )}

        {onBackup && (
          <Button variant="outline" onClick={onBackup}>
            <Save className="mr-2 h-4 w-4" />
            Backup
          </Button>
        )}

        {onImport && (
          <div className="relative">
            <input
              type="file"
              accept=".json"
              onChange={handleFileUpload}
              className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
            />
            <Button variant="outline">
              <Upload className="mr-2 h-4 w-4" />
              Importar JSON
            </Button>
          </div>
        )}
      </div>
    </div>
  )
}
[V0_FILE]typescript:file="lib/api.ts" isEdit="true" isMerged="true"
export const api = {
  // Tasks
  async getTasks() {
    try {
      const response = await fetch(`/api/tasks`)
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(`Failed to fetch tasks: ${errorData.error || response.statusText}`)
      }
      return response.json()
    } catch (error) {
      console.error("API Error - getTasks:", error)
      throw error
    }
  },

  async createTask(task: any) {
    try {
      const response = await fetch(`/api/tasks`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(task),
      })
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(`Failed to create task: ${errorData.error || response.statusText}`)
      }
      return response.json()
    } catch (error) {
      console.error("API Error - createTask:", error)
      throw error
    }
  },

  async updateTask(id: string, task: any) {
    try {
      const response = await fetch(`/api/tasks/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(task),
      })
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(`Failed to update task: ${errorData.error || response.statusText}`)
      }
      return response.json()
    } catch (error) {
      console.error("API Error - updateTask:", error)
      throw error
    }
  },

  async deleteTask(id: string) {
    try {
      const response = await fetch(`/api/tasks/${id}`, {
        method: "DELETE",
      })
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(`Failed to delete task: ${errorData.error || response.statusText}`)
      }
      return response.json()
    } catch (error) {
      console.error("API Error - deleteTask:", error)
      throw error
    }
  },

  // Bulk operations
  async bulkDeleteTasks(ids: string[]) {
    try {
      console.log("Sending bulk delete request with IDs:", ids)

      const response = await fetch(`/api/tasks/bulk`, {
        method: "DELETE",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ids }),
      })

      const result = await response.json()
      console.log("Bulk delete response from server:", result)

      if (!response.ok) {
        console.error("Error response from server:", result)
        throw new Error(`Failed to delete tasks: ${result.error || response.statusText}`)
      }

      // Verificar explícitamente la estructura de la respuesta
      if (typeof result.deletedCount !== "number") {
        console.error("Invalid response format - deletedCount is not a number:", result)
        return {
          success: true,
          deletedCount: ids.length, // Fallback: asumir que todas las tareas se eliminaron
          deletedIds: ids,
        }
      }

      return result
    } catch (error) {
      console.error("API Error - bulkDeleteTasks:", error)
      throw error
    }
  },

  async bulkUpdateTaskStatus(ids: string[], status: string) {
    try {
      console.log("Sending bulk update request with IDs:", ids, "and status:", status)

      const response = await fetch(`/api/tasks/bulk`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ids, status }),
      })

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(`Failed to update tasks: ${errorData.error || response.statusText}`)
      }

      const result = await response.json()
      console.log("Bulk update response:", result)
      return result
    } catch (error) {
      console.error("API Error - bulkUpdateTaskStatus:", error)
      throw error
    }
  },

  // Personnel
  async getPersonnel() {
    try {
      const response = await fetch(`/api/personnel`)
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(`Failed to fetch personnel: ${errorData.error || response.statusText}`)
      }
      return response.json()
    } catch (error) {
      console.error("API Error - getPersonnel:", error)
      throw error
    }
  },

  async getPersonnelWithIds() {
    try {
      const response = await fetch(`/api/personnel?includeIds=true`)
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(`Failed to fetch personnel: ${errorData.error || response.statusText}`)
      }
      return response.json()
    } catch (error) {
      console.error("API Error - getPersonnelWithIds:", error)
      throw error
    }
  },

  async addPersonnel(type: string, name: string) {
    try {
      const response = await fetch(`/api/personnel`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ type, name }),
      })
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(`Failed to add personnel: ${errorData.error || response.statusText}`)
      }
      return response.json()
    } catch (error) {
      console.error("API Error - addPersonnel:", error)
      throw error
    }
  },

  async updatePersonnel(id: string, type: string, name: string) {
    try {
      const response = await fetch(`/api/personnel/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ type, name }),
      })
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(`Failed to update personnel: ${errorData.error || response.statusText}`)
      }
      return response.json()
    } catch (error) {
      console.error("API Error - updatePersonnel:", error)
      throw error
    }
  },

  async deletePersonnel(id: string) {
    try {
      const response = await fetch(`/api/personnel/${id}`, {
        method: "DELETE",
      })
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(`Failed to delete personnel: ${errorData.error || response.statusText}`)
      }
      return response.json()
    } catch (error) {
      console.error("API Error - deletePersonnel:", error)
      throw error
    }
  },

  // Export
  async exportTasks(format: "json" | "csv") {
    try {
      const response = await fetch(`/api/tasks/export?format=${format}`)
      if (!response.ok) {
        const errorData = await response.text()
        throw new Error(`Failed to export tasks: ${errorData || response.statusText}`)
      }
      return response.blob()
    } catch (error) {
      console.error("API Error - exportTasks:", error)
      throw error
    }
  },

  // Initialize
  async initialize() {
    try {
      const response = await fetch(`/api/init`, {
        method: "POST",
      })
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(`Failed to initialize: ${errorData.error || response.statusText}`)
      }
      return response.json()
    } catch (error) {
      console.error("API Error - initialize:", error)
      throw error
    }
  },
}
[V0_FILE]sql:file="sample-tasks.sql" isMerged="true"
-- Script para añadir tareas de ejemplo
-- Ejecutar este script directamente en la base de datos para añadir tareas de ejemplo

-- Tarea 1: Implementación de firewall de nueva generación
INSERT INTO tasks (
  ticket, cis_control, project_action, summary, description, 
  risk, impact, raw_probability, raw_impact, raw_risk, 
  avoid, mitigate, transfer, accept, treatment, 
  treated_probability, treated_impact, current_risk, next_review, 
  department, owner, coordinator, technician, status, last_check, comments
) VALUES (
  'CRQ000123', 9, 'Implementación de firewall', 'Implementación de firewall de nueva generación', 
  'Implementar solución de firewall de nueva generación para mejorar la seguridad perimetral y el control de aplicaciones.',
  'Acceso no autorizado a la red', 'Alto', 75, 80, 60,
  0, 1, 0, 0, 'Implementar firewall con reglas estrictas y monitorización continua',
  35, 40, 14, '2023-12-15',
  'Seguridad', 'Juan Pérez', 'Ana Martínez', 'Carlos López', 
  'In Progress', '2023-09-01', 'Se ha completado la fase de diseño y se está procediendo con la implementación'
);

-- Tarea 2: Actualización de sistemas operativos
INSERT INTO tasks (
  ticket, cis_control, project_action, summary, description, 
  risk, impact, raw_probability, raw_impact, raw_risk, 
  avoid, mitigate, transfer, accept, treatment, 
  treated_probability, treated_impact, current_risk, next_review, 
  department, owner, coordinator, technician, status, last_check, comments
) VALUES (
  'CRQ000124', 3, 'Actualización de SO', 'Actualización de sistemas operativos', 
  'Actualizar todos los sistemas operativos a las últimas versiones con soporte para eliminar vulnerabilidades conocidas.',
  'Explotación de vulnerabilidades', 'Medio', 65, 70, 45,
  0, 1, 0, 0, 'Implementar proceso de actualización automática y gestión de parches',
  30, 35, 10, '2023-11-30',
  'Infraestructura', 'María García', 'Pedro Rodríguez', 'Laura Sánchez', 
  'Scheduled', '2023-08-15', 'Se ha programado la actualización para realizarse en fases durante los próximos fines de semana'
);

-- Tarea 3: Implementación de autenticación multifactor
INSERT INTO tasks (
  ticket, cis_control, project_action, summary, description, 
  risk, impact, raw_probability, raw_impact, raw_risk, 
  avoid, mitigate, transfer, accept, treatment, 
  treated_probability, treated_impact, current_risk, next_review, 
  department, owner, coordinator, technician, status, last_check, comments
) VALUES (
  'CRQ000125', 5, 'Implementación MFA', 'Implementación de autenticación multifactor', 
  'Implementar autenticación multifactor para todos los accesos a sistemas críticos y cuentas privilegiadas.',
  'Robo de credenciales', 'Alto', 80, 85, 68,
  0, 1, 0, 0, 'Implementar MFA basado en aplicación móvil y tokens hardware para administradores',
  25, 85, 21, '2023-12-01',
  'Seguridad', 'Carlos López', 'Ana Martínez', 'Miguel Torres', 
  'In Progress', '2023-09-10', 'Se ha completado la implementación para cuentas de administrador, pendiente para usuarios estándar'
);

-- Tarea 4: Revisión de permisos de acceso
INSERT INTO tasks (
  ticket, cis_control, project_action, summary, description, 
  risk, impact, raw_probability, raw_impact, raw_risk, 
  avoid, mitigate, transfer, accept, treatment, 
  treated_probability, treated_impact, current_risk, next_review, 
  department, owner, coordinator, technician, status, last_check, comments
) VALUES (
  'CRQ000126', 16, 'Revisión de permisos', 'Revisión de permisos de acceso', 
  'Realizar una revisión completa de los permisos de acceso a sistemas y datos para asegurar el principio de mínimo privilegio.',
  'Acceso excesivo a datos sensibles', 'Medio', 70, 65, 45,
  0, 1, 0, 0, 'Implementar proceso de revisión trimestral de permisos y ajuste según necesidad',
  35, 40, 14, '2023-11-15',
  'Seguridad', 'María García', 'Pedro Rodríguez', 'Sofia Hernández', 
  'Pending', '2023-08-20', 'Se está recopilando información de todos los sistemas para iniciar la revisión'
);

-- Tarea 5: Implementación de sistema de gestión de vulnerabilidades
INSERT INTO tasks (
  ticket, cis_control, project_action, summary, description, 
  risk, impact, raw_probability, raw_impact, raw_risk, 
  avoid, mitigate, transfer, accept, treatment, 
  treated_probability, treated_impact, current_risk, next_review, 
  department, owner, coordinator, technician, status, last_check, comments
) VALUES (
  'CRQ000127', 4, 'Gestión de vulnerabilidades', 'Implementación de sistema de gestión de vulnerabilidades', 
  'Implementar un sistema automatizado de escaneo y gestión de vulnerabilidades para toda la infraestructura.',
  'Vulnerabilidades no detectadas', 'Alto', 75, 80, 60,
  0, 1, 0, 0, 'Implementar escaneos semanales y proceso de remediación priorizado',
  30, 40, 12, '2023-12-10',
  'Seguridad', 'Juan Pérez', 'Laura García', 'Carlos López', 
  'Request for Authorization', '2023-09-05', 'Se ha seleccionado la herramienta y se está esperando aprobación presupuestaria'
);

-- Tarea 6: Desarrollo de plan de respuesta a incidentes
INSERT INTO tasks (
  ticket, cis_control, project_action, summary, description, 
  risk, impact, raw_probability, raw_impact, raw_risk, 
  avoid, mitigate, transfer, accept, treatment, 
  treated_probability, treated_impact, current_risk, next_review, 
  department, owner, coordinator, technician, status, last_check, comments
) VALUES (
  'CRQ000128', 19, 'Plan de respuesta', 'Desarrollo de plan de respuesta a incidentes', 
  'Desarrollar y documentar un plan completo de respuesta a incidentes de seguridad con roles y responsabilidades claras.',
  'Respuesta inadecuada ante incidentes', 'Alto', 70, 85, 59,
  0, 1, 0, 0, 'Desarrollar plan, realizar formación y simulacros periódicos',
  35, 50, 17, '2023-11-20',
  'Seguridad', 'Ana Martínez', 'Juan Pérez', 'María García', 
  'In Progress', '2023-08-25', 'Se ha completado el borrador inicial y se está revisando con las partes interesadas'
);

-- Tarea 7: Implementación de cifrado de datos sensibles
INSERT INTO tasks (
  ticket, cis_control, project_action, summary, description, 
  risk, impact, raw_probability, raw_impact, raw_risk, 
  avoid, mitigate, transfer, accept, treatment, 
  treated_probability, treated_impact, current_risk, next_review, 
  department, owner, coordinator, technician, status, last_check, comments
) VALUES (
  'CRQ000129', 14, 'Cifrado de datos', 'Implementación de cifrado de datos sensibles', 
  'Implementar soluciones de cifrado para datos sensibles en reposo y en tránsito en todos los sistemas.',
  'Exposición de datos confidenciales', 'Crítico', 65, 90, 58,
  0, 1, 0, 0, 'Implementar cifrado AES-256 para datos en reposo y TLS 1.3 para datos en tránsito',
  25, 60, 15, '2023-12-05',
  'Seguridad', 'Carlos López', 'María García', 'Pedro Rodríguez', 
  'Scheduled', '2023-09-15', 'Se ha completado el inventario de datos sensibles y se está preparando la implementación'
);

-- Tarea 8: Segmentación de red
INSERT INTO tasks (
  ticket, cis_control, project_action, summary, description, 
  risk, impact, raw_probability, raw_impact, raw_risk, 
  avoid, mitigate, transfer, accept, treatment, 
  treated_probability, treated_impact, current_risk, next_review, 
  department, owner, coordinator, technician, status, last_check, comments
) VALUES (
  'CRQ000130', 11, 'Segmentación de red', 'Implementación de segmentación de red', 
  'Rediseñar la arquitectura de red para implementar segmentación adecuada y reducir la superficie de ataque.',
  'Movimiento lateral de atacantes', 'Alto', 75, 80, 60,
  0, 1, 0, 0, 'Implementar VLANs, firewalls internos y controles de acceso entre segmentos',
  30, 45, 13, '2023-11-25',
  'Infraestructura', 'Pedro Rodríguez', 'Juan Pérez', 'Miguel Torres', 
  'In Progress', '2023-08-30', 'Se ha completado el diseño y se está implementando en el entorno de pruebas'
);

-- Tarea 9: Implementación de sistema de gestión de logs
INSERT INTO tasks (
  ticket, cis_control, project_action, summary, description, 
  risk, impact, raw_probability, raw_impact, raw_risk, 
  avoid, mitigate, transfer, accept, treatment, 
  treated_probability, treated_impact, current_risk, next_review, 
  department, owner, coordinator, technician, status, last_check, comments
) VALUES (
  'CRQ000131', 6, 'Gestión de logs', 'Implementación de sistema de gestión de logs', 
  'Implementar un sistema centralizado de recolección, análisis y almacenamiento de logs para mejorar la detección de incidentes.',
  'Detección tardía de incidentes', 'Medio', 70, 65, 45,
  0, 1, 0, 0, 'Implementar SIEM con correlación de eventos y alertas automatizadas',
  35, 40, 14, '2023-12-20',
  'Seguridad', 'Laura García', 'Carlos López', 'Ana Martínez', 
  'Pending', '2023-09-20', 'Se están evaluando diferentes soluciones SIEM para seleccionar la más adecuada'
);

-- Tarea 10: Desarrollo de programa de concienciación en seguridad
INSERT INTO tasks (
  ticket, cis_control, project_action, summary, description, 
  risk, impact, raw_probability, raw_impact, raw_risk, 
  avoid, mitigate, transfer, accept, treatment, 
  treated_probability, treated_impact, current_risk, next_review, 
  department, owner, coordinator, technician, status, last_check, comments
) VALUES (
  'CRQ000132', 17, 'Concienciación en seguridad', 'Desarrollo de programa de concienciación en seguridad', 
  'Desarrollar e implementar un programa completo de concienciación en seguridad para todos los empleados.',
  'Error humano en seguridad', 'Alto', 85, 75, 63,
  0, 1, 0, 0, 'Implementar formación inicial, recordatorios periódicos y simulacros de phishing',
  40, 50, 20, '2023-11-10',
  'Recursos Humanos', 'María García', 'Ana Martínez', 'Juan Pérez', 
  'In Progress', '2023-09-25', 'Se ha desarrollado el contenido inicial y se está preparando la plataforma de formación'
);
[V0_FILE]sql:file="init-db.sql" isEdit="true" isMerged="true"
-- Create personnel table if it doesn't exist
CREATE TABLE IF NOT EXISTS personnel (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(name, type)
);

-- Create tasks table if it doesn't exist
CREATE TABLE IF NOT EXISTS tasks (
  id VARCHAR(255) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  ticket VARCHAR(255),
  cis_control INTEGER NOT NULL,
  project_action VARCHAR(255) NOT NULL,
  summary VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  risk VARCHAR(255),
  impact VARCHAR(255),
  raw_probability FLOAT NOT NULL,
  raw_impact FLOAT NOT NULL,
  raw_risk FLOAT NOT NULL,
  avoid FLOAT DEFAULT 0,
  mitigate FLOAT DEFAULT 0,
  transfer FLOAT DEFAULT 0,
  accept FLOAT,
  treatment TEXT NOT NULL,
  treated_probability FLOAT NOT NULL,
  treated_impact FLOAT NOT NULL,
  current_risk FLOAT NOT NULL,
  next_review VARCHAR(255) NOT NULL,
  department VARCHAR(255) NOT NULL,
  owner VARCHAR(255) NOT NULL,
  coordinator VARCHAR(255) NOT NULL,
  technician VARCHAR(255) NOT NULL,
  creation_date VARCHAR(255) DEFAULT CURRENT_DATE::text,
  status VARCHAR(255) NOT NULL,
  last_check VARCHAR(255) NOT NULL,
  comments TEXT,
  completion_date VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_department ON tasks(department);
CREATE INDEX IF NOT EXISTS idx_tasks_owner ON tasks(owner);
CREATE INDEX IF NOT EXISTS idx_tasks_current_risk ON tasks(current_risk);

-- Insert default personnel if not exists
INSERT INTO personnel (name, type) VALUES 
  ('Juan Pérez', 'owners'),
  ('María García', 'owners'),
  ('Carlos López', 'owners'),
  ('Laura García', 'coordinators'),
  ('Ana Martínez', 'coordinators'),
  ('Pedro Rodríguez', 'coordinators'),
  ('Carlos López', 'technicians'),
  ('Miguel Torres', 'technicians'),
  ('Sofia Hernández', 'technicians')
ON CONFLICT (name, type) DO NOTHING;

-- Insert sample tasks
INSERT INTO tasks (
  id, ticket, cis_control, project_action, summary, description, 
  risk, impact, raw_probability, raw_impact, raw_risk, 
  avoid, mitigate, transfer, accept, treatment, 
  treated_probability, treated_impact, current_risk, next_review, 
  department, owner, coordinator, technician, creation_date, status, last_check, comments
) VALUES 
(
  'task-001', 'CRQ000123', 9, 'Implementación de firewall', 'Implementación de firewall de nueva generación', 
  'Implementar solución de firewall de nueva generación para mejorar la seguridad perimetral y el control de aplicaciones.',
  'Acceso no autorizado a la red', 'Alto', 75, 80, 60,
  0, 1, 0, 0, 'Implementar firewall con reglas estrictas y monitorización continua',
  35, 40, 14, '2024-12-15',
  'Seguridad', 'Juan Pérez', 'Ana Martínez', 'Carlos López', 
  '2024-01-15', 'In Progress', '2024-09-01', 'Se ha completado la fase de diseño y se está procediendo con la implementación'
),
(
  'task-002', 'CRQ000124', 3, 'Actualización de SO', 'Actualización de sistemas operativos', 
  'Actualizar todos los sistemas operativos a las últimas versiones con soporte para eliminar vulnerabilidades conocidas.',
  'Explotación de vulnerabilidades', 'Medio', 65, 70, 45,
  0, 1, 0, 0, 'Implementar proceso de actualización automática y gestión de parches',
  30, 35, 10, '2024-11-30',
  'Infraestructura', 'María García', 'Pedro Rodríguez', 'Laura Sánchez', 
  '2024-02-01', 'Scheduled', '2024-08-15', 'Se ha programado la actualización para realizarse en fases durante los próximos fines de semana'
),
(
  'task-003', 'CRQ000125', 5, 'Implementación MFA', 'Implementación de autenticación multifactor', 
  'Implementar autenticación multifactor para todos los accesos a sistemas críticos y cuentas privilegiadas.',
  'Robo de credenciales', 'Alto', 80, 85, 68,
  0, 1, 0, 0, 'Implementar MFA basado en aplicación móvil y tokens hardware para administradores',
  25, 85, 21, '2024-12-01',
  'Seguridad', 'Carlos López', 'Ana Martínez', 'Miguel Torres', 
  '2024-01-20', 'In Progress', '2024-09-10', 'Se ha completado la implementación para cuentas de administrador, pendiente para usuarios estándar'
),
(
  'task-004', 'CRQ000126', 16, 'Revisión de permisos', 'Revisión de permisos de acceso', 
  'Realizar una revisión completa de los permisos de acceso a sistemas y datos para asegurar el principio de mínimo privilegio.',
  'Acceso excesivo a datos sensibles', 'Medio', 70, 65, 45,
  0, 1, 0, 0, 'Implementar proceso de revisión trimestral de permisos y ajuste según necesidad',
  35, 40, 14, '2024-11-15',
  'Seguridad', 'María García', 'Pedro Rodríguez', 'Sofia Hernández', 
  '2024-02-10', 'Pending', '2024-08-20', 'Se está recopilando información de todos los sistemas para iniciar la revisión'
),
(
  'task-005', 'CRQ000127', 4, 'Gestión de vulnerabilidades', 'Implementación de sistema de gestión de vulnerabilidades', 
  'Implementar un sistema automatizado de escaneo y gestión de vulnerabilidades para toda la infraestructura.',
  'Vulnerabilidades no detectadas', 'Alto', 75, 80, 60,
  0, 1, 0, 0, 'Implementar escaneos semanales y proceso de remediación priorizado',
  30, 40, 12, '2024-12-10',
  'Seguridad', 'Juan Pérez', 'Laura García', 'Carlos López', 
  '2024-01-25', 'Request for Authorization', '2024-09-05', 'Se ha seleccionado la herramienta y se está esperando aprobación presupuestaria'
),
(
  'task-006', 'CRQ000128', 19, 'Plan de respuesta', 'Desarrollo de plan de respuesta a incidentes', 
  'Desarrollar y documentar un plan completo de respuesta a incidentes de seguridad con roles y responsabilidades claras.',
  'Respuesta inadecuada ante incidentes', 'Alto', 70, 85, 59,
  0, 1, 0, 0, 'Desarrollar plan, realizar formación y simulacros periódicos',
  35, 50, 17, '2024-11-20',
  'Seguridad', 'Ana Martínez', 'Juan Pérez', 'María García', 
  '2024-02-05', 'In Progress', '2024-08-25', 'Se ha completado el borrador inicial y se está revisando con las partes interesadas'
),
(
  'task-007', 'CRQ000129', 14, 'Cifrado de datos', 'Implementación de cifrado de datos sensibles', 
  'Implementar soluciones de cifrado para datos sensibles en reposo y en tránsito en todos los sistemas.',
  'Exposición de datos confidenciales', 'Crítico', 65, 90, 58,
  0, 1, 0, 0, 'Implementar cifrado AES-256 para datos en reposo y TLS 1.3 para datos en tránsito',
  25, 60, 15, '2024-12-05',
  'Seguridad', 'Carlos López', 'María García', 'Pedro Rodríguez', 
  '2024-01-30', 'Scheduled', '2024-09-15', 'Se ha completado el inventario de datos sensibles y se está preparando la implementación'
),
(
  'task-008', 'CRQ000130', 11, 'Segmentación de red', 'Implementación de segmentación de red', 
  'Rediseñar la arquitectura de red para implementar segmentación adecuada y reducir la superficie de ataque.',
  'Movimiento lateral de atacantes', 'Alto', 75, 80, 60,
  0, 1, 0, 0, 'Implementar VLANs, firewalls internos y controles de acceso entre segmentos',
  30, 45, 13, '2024-11-25',
  'Infraestructura', 'Pedro Rodríguez', 'Juan Pérez', 'Miguel Torres', 
  '2024-02-15', 'In Progress', '2024-08-30', 'Se ha completado el diseño y se está implementando en el entorno de pruebas'
),
(
  'task-009', 'CRQ000131', 6, 'Gestión de logs', 'Implementación de sistema de gestión de logs', 
  'Implementar un sistema centralizado de recolección, análisis y almacenamiento de logs para mejorar la detección de incidentes.',
  'Detección tardía de incidentes', 'Medio', 70, 65, 45,
  0, 1, 0, 0, 'Implementar SIEM con correlación de eventos y alertas automatizadas',
  35, 40, 14, '2024-12-20',
  'Seguridad', 'Laura García', 'Carlos López', 'Ana Martínez', 
  '2024-02-20', 'Pending', '2024-09-20', 'Se están evaluando diferentes soluciones SIEM para seleccionar la más adecuada'
),
(
  'task-010', 'CRQ000132', 17, 'Concienciación en seguridad', 'Desarrollo de programa de concienciación en seguridad', 
  'Desarrollar e implementar un programa completo de concienciación en seguridad para todos los empleados.',
  'Error humano en seguridad', 'Alto', 85, 75, 63,
  0, 1, 0, 0, 'Implementar formación inicial, recordatorios periódicos y simulacros de phishing',
  40, 50, 20, '2024-11-10',
  'Recursos Humanos', 'María García', 'Ana Martínez', 'Juan Pérez', 
  '2024-02-25', 'In Progress', '2024-09-25', 'Se ha desarrollado el contenido inicial y se está preparando la plataforma de formación'
)
ON CONFLICT (id) DO NOTHING;
[V0_FILE]shellscript:file="update-database.sh" isMerged="true"
#!/bin/bash

# Script para actualizar la base de datos con los últimos cambios

echo "Actualizando la base de datos..."

# Variables de conexión
DB_USER="cybersec_user"
DB_NAME="cybersec_tasks"
DB_HOST="localhost"
DB_PORT="5432"

# Si estás usando Docker, puedes ejecutar los comandos así:
if [ "$1" == "docker" ]; then
    echo "Ejecutando actualización en Docker..."
    
    # Crear índices si no existen
    docker exec -i cybersec-db psql -U $DB_USER -d $DB_NAME << EOF
-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_department ON tasks(department);
CREATE INDEX IF NOT EXISTS idx_tasks_owner ON tasks(owner);
CREATE INDEX IF NOT EXISTS idx_tasks_current_risk ON tasks(current_risk);

-- Añadir constraint único a la tabla personnel si no existe
ALTER TABLE personnel ADD CONSTRAINT IF NOT EXISTS unique_personnel_name_type UNIQUE(name, type);

-- Verificar que las columnas necesarias existen
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS creation_date VARCHAR(255) DEFAULT CURRENT_DATE::text;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS completion_date VARCHAR(255);

-- Actualizar las fechas de las tareas existentes si es necesario
UPDATE tasks SET creation_date = CURRENT_DATE::text WHERE creation_date IS NULL;

EOF
    
    echo "Base de datos actualizada correctamente en Docker."
else
    # Ejecutar directamente con psql
    echo "Ejecutando actualización local..."
    
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME << EOF
-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_department ON tasks(department);
CREATE INDEX IF NOT EXISTS idx_tasks_owner ON tasks(owner);
CREATE INDEX IF NOT EXISTS idx_tasks_current_risk ON tasks(current_risk);

-- Añadir constraint único a la tabla personnel si no existe
ALTER TABLE personnel ADD CONSTRAINT IF NOT EXISTS unique_personnel_name_type UNIQUE(name, type);

-- Verificar que las columnas necesarias existen
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS creation_date VARCHAR(255) DEFAULT CURRENT_DATE::text;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS completion_date VARCHAR(255);

-- Actualizar las fechas de las tareas existentes si es necesario
UPDATE tasks SET creation_date = CURRENT_DATE::text WHERE creation_date IS NULL;

EOF
    
    echo "Base de datos actualizada correctamente."
fi

echo "Proceso completado."
[V0_FILE]typescript:file="lib/db.ts" isEdit="true" isMerged="true"
import { Pool } from "pg"

// Verificar que DATABASE_URL esté definido
if (!process.env.DATABASE_URL) {
  console.error("DATABASE_URL is not defined in environment variables")
  throw new Error("DATABASE_URL is not defined")
}

// Crear pool de conexiones PostgreSQL
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === "production" ? { rejectUnauthorized: false } : false,
})

// Función para ejecutar consultas SQL (compatible con la API anterior)
export async function sql(strings: TemplateStringsArray, ...values: any[]) {
  const client = await pool.connect()
  try {
    // Construir la consulta SQL
    let query = strings[0]
    const params = []

    for (let i = 0; i < values.length; i++) {
      params.push(values[i])
      query += `$${i + 1}${strings[i + 1] || ""}`
    }

    // Ejecutar la consulta
    const result = await client.query(query, params)
    return result.rows
  } finally {
    client.release()
  }
}

// Probar la conexión
export async function testConnection() {
  try {
    const result = await sql`SELECT 1 as test`
    return result[0].test === 1
  } catch (error) {
    console.error("Database connection test failed:", error)
    return false
  }
}
[V0_FILE]javascript:file="next.config.mjs" isEdit="true" isMerged="true"
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  // Eliminada la referencia a @neondatabase/serverless
  eslint: {
    ignoreDuringBuilds: true,
  },
  typescript: {
    ignoreBuildErrors: true,
  },
  images: {
    unoptimized: true,
  },
}

export default nextConfig
[V0_FILE]json:file="package.json" isEdit="true" isMerged="true"
{
  "name": "cybersec-tasks",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "@radix-ui/react-checkbox": "^1.0.4",
    "@radix-ui/react-dialog": "^1.0.5",
    "@radix-ui/react-dropdown-menu": "^2.0.6",
    "@radix-ui/react-label": "^2.0.2",
    "@radix-ui/react-popover": "^1.0.7",
    "@radix-ui/react-select": "^2.0.0",
    "@radix-ui/react-separator": "^1.0.3",
    "@radix-ui/react-slot": "^1.0.2",
    "@radix-ui/react-tabs": "^1.0.4",
    "@radix-ui/react-toast": "^1.1.5",
    "chart.js": "^4.4.1",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.0.0",
    "date-fns": "^2.30.0",
    "exceljs": "^4.4.0",
    "lucide-react": "^0.294.0",
    "next": "14.0.4",
    "pg": "^8.11.3",
    "react": "^18",
    "react-chartjs-2": "^5.2.0",
    "react-day-picker": "^8.9.1",
    "react-dom": "^18",
    "tailwind-merge": "^2.1.0",
    "tailwindcss-animate": "^1.0.7"
  },
  "devDependencies": {
    "@types/node": "^20",
    "@types/pg": "^8.10.9",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "autoprefixer": "^10.0.1",
    "eslint": "^8",
    "eslint-config-next": "14.0.4",
    "postcss": "^8",
    "tailwindcss": "^3.3.0",
    "typescript": "^5"
  }
}
[V0_FILE]yaml:file="docker-compose.offline.yml" isFixed="true" isEdit="true" isQuickEdit="true" isMerged="true"
version: '3.8'

services:
  db:
    image: bitnami/postgresql:15
    container_name: cybersec-db
    restart: always
    ports:
      - "5432:5432"
    environment:
      POSTGRESQL_USERNAME: cybersec_user
      POSTGRESQL_PASSWORD: cybersec_password
      POSTGRESQL_DATABASE: cybersec_tasks
    volumes:
      - postgres_data:/bitnami/postgresql
      - ./init-db.sql:/docker-entrypoint-initdb.d/init-db.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U cybersec_user -d cybersec_tasks"]
      interval: 5s
      timeout: 5s
      retries: 5

  app:
    image: cybersec-app:offline
    container_name: cybersec-app
    restart: always
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://cybersec_user:cybersec_password@db:5432/cybersec_tasks
      - NODE_ENV=production
    depends_on:
      db:
        condition: service_healthy

volumes:
  postgres_data:
[V0_FILE]dockerfile:file="Dockerfile.offline" isEdit="true" isMerged="true"
# Etapa de construcción
FROM bitnami/node:18 AS builder

WORKDIR /app

# Copiar archivos de dependencias
COPY package.json package-lock.json* ./

# Copiar node_modules preinstalados (se asume que ya están en el directorio)
COPY node_modules ./node_modules

# Copiar el resto del código fuente
COPY . .

# Construir la aplicación
ENV NEXT_TELEMETRY_DISABLED 1
ENV NODE_ENV production
RUN npm run build

# Etapa de producción
FROM bitnami/node:18 AS runner

WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

# Copiar archivos necesarios
COPY --from=builder /app/public ./public
COPY --from=builder /app/init-db.sql ./init-db.sql
COPY --from=builder /app/sample-tasks.sql ./sample-tasks.sql

# Crear directorio para archivos de Next.js
RUN mkdir -p .next

# Copiar archivos de construcción
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

# Las imágenes de Bitnami ya tienen un usuario no root configurado
CMD ["node", "server.js"]
[V0_FILE]dockerfile:file="Dockerfile" isEdit="true" isMerged="true"
# Etapa de construcción
FROM bitnami/node:18 AS builder

WORKDIR /app

# Copiar archivos de dependencias
COPY package.json package-lock.json* ./
RUN npm ci

# Copiar el resto del código fuente
COPY . .

# Construir la aplicación
ENV NEXT_TELEMETRY_DISABLED 1
ENV NODE_ENV production
RUN npm run build

# Etapa de producción
FROM bitnami/node:18 AS runner

WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

# Copiar archivos necesarios
COPY --from=builder /app/public ./public
COPY --from=builder /app/init-db.sql ./init-db.sql
COPY --from=builder /app/sample-tasks.sql ./sample-tasks.sql

# Crear directorio para archivos de Next.js
RUN mkdir -p .next

# Copiar archivos de construcción
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

# Las imágenes de Bitnami ya tienen un usuario no root configurado
CMD ["node", "server.js"]
[V0_FILE]yaml:file="docker-compose.yml" isFixed="true" isEdit="true" isQuickEdit="true" isMerged="true"
version: '3.8'

services:
  db:
    image: bitnami/postgresql:15
    container_name: cybersec-db
    restart: always
    ports:
      - "5432:5432"
    environment:
      POSTGRESQL_USERNAME: cybersec_user
      POSTGRESQL_PASSWORD: cybersec_password
      POSTGRESQL_DATABASE: cybersec_tasks
    volumes:
      - postgres_data:/bitnami/postgresql
      - ./init-db.sql:/docker-entrypoint-initdb.d/init-db.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U cybersec_user -d cybersec_tasks"]
      interval: 5s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: cybersec-backend
    restart: always
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://cybersec_user:cybersec_password@db:5432/cybersec_tasks
    depends_on:
      db:
        condition: service_healthy

  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: cybersec-app
    restart: always
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://cybersec_user:cybersec_password@db:5432/cybersec_tasks
      - BACKEND_URL=http://backend:8000
      - NODE_ENV=production
    depends_on:
      - backend

volumes:
  postgres_data:
[V0_FILE]dockerfile:file="backend/Dockerfile" isEdit="true" isMerged="true"
FROM bitnami/python:3.11

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
[V0_FILE]shellscript:file="scripts/prepare-offline-package.sh" isEdit="true" isMerged="true"
#!/bin/bash
set -e

echo "Preparando paquete offline para CyberSec Tasks..."

# Crear directorio temporal
TEMP_DIR="cybersec-tasks-offline"
rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR

# Copiar archivos del proyecto
echo "Copiando archivos del proyecto..."
cp -r $(ls -A | grep -v "node_modules\|.next\|.git\|$TEMP_DIR") $TEMP_DIR/

# Instalar dependencias
echo "Instalando dependencias..."
cd $TEMP_DIR
npm ci
cd ..

# Descargar imágenes de Docker
echo "Descargando imágenes de Docker..."
docker pull bitnami/node:18
docker pull bitnami/postgresql:15
docker pull bitnami/python:3.11

# Guardar imágenes de Docker
echo "Guardando imágenes de Docker..."
mkdir -p $TEMP_DIR/docker-images
docker save bitnami/node:18 bitnami/postgresql:15 bitnami/python:3.11 -o $TEMP_DIR/docker-images/images.tar

# Crear script de instalación para Linux/Mac
echo "Creando script de instalación para Linux/Mac..."
cat > $TEMP_DIR/install.sh << 'EOF'
#!/bin/bash
set -e

echo "Instalando CyberSec Tasks en modo offline..."

# Cargar imágenes de Docker
echo "Cargando imágenes de Docker..."
docker load -i docker-images/images.tar

# Construir imagen de la aplicación
echo "Construyendo imagen de la aplicación..."
docker build -t cybersec-app:offline -f Dockerfile.offline .

# Iniciar servicios
echo "Iniciando servicios..."
docker-compose -f docker-compose.offline.yml up -d

echo "Instalación completada. La aplicación está disponible en http://localhost:3000"
EOF
chmod +x $TEMP_DIR/install.sh

# Crear script de instalación para Windows
echo "Creando script de instalación para Windows..."
cat > $TEMP_DIR/install.bat << 'EOF'
@echo off
echo Instalando CyberSec Tasks en modo offline...

REM Cargar imágenes de Docker
echo Cargando imágenes de Docker...
docker load -i docker-images\images.tar

REM Construir imagen de la aplicación
echo Construyendo imagen de la aplicación...
docker build -t cybersec-app:offline -f Dockerfile.offline .

REM Iniciar servicios
echo Iniciando servicios...
docker-compose -f docker-compose.offline.yml up -d

echo Instalación completada. La aplicación está disponible en http://localhost:3000
EOF

# Comprimir todo
echo "Comprimiendo paquete..."
tar -czf cybersec-tasks-offline.tar.gz $TEMP_DIR

echo "Paquete offline creado: cybersec-tasks-offline.tar.gz"
echo "Puedes transferir este archivo a un entorno sin conexión a internet y ejecutar el script install.sh o install.bat para instalar la aplicación."
[V0_FILE]markdown:file="docs/offline-installation.md" isEdit="true" isMerged="true"
# Instalación sin conexión a internet

Esta guía explica cómo instalar CyberSec Tasks en un entorno sin conexión a internet.

## Preparación (en un entorno CON internet)

1. Clona el repositorio:
   \`\`\`bash
   git clone https://github.com/tu-usuario/cybersec-tasks.git
   cd cybersec-tasks
   \`\`\`

2. Ejecuta el script de preparación:
   \`\`\`bash
   # Linux/Mac
   chmod +x scripts/prepare-offline-package.sh
   ./scripts/prepare-offline-package.sh

   # Windows PowerShell
   .\scripts\prepare-offline-package.ps1
   \`\`\`

3. Esto creará un archivo comprimido (`cybersec-tasks-offline.tar.gz` o `.zip`) con todo lo necesario.

## Instalación (en un entorno SIN internet)

1. Transfiere el archivo comprimido al entorno sin conexión a internet.

2. Descomprime el archivo:
   \`\`\`bash
   # Linux/Mac
   tar -xzf cybersec-tasks-offline.tar.gz
   cd cybersec-tasks-offline

   # Windows
   # Descomprimir usando el Explorador de Windows
   # Navegar a la carpeta cybersec-tasks-offline
   \`\`\`

3. Ejecuta el script de instalación:
   \`\`\`bash
   # Linux/Mac
   chmod +x install.sh
   ./install.sh

   # Windows
   install.bat
   \`\`\`

4. La aplicación estará disponible en http://localhost:3000

## Características de seguridad

- Utilizamos imágenes de Bitnami para Docker, que son más seguras y tienen menos vulnerabilidades
- PostgreSQL de Bitnami está configurado con las mejores prácticas de seguridad
- Node.js de Bitnami se ejecuta como usuario no root por defecto

## Solución de problemas

### Problemas con PostgreSQL

Si tienes problemas con la base de datos, puedes verificar los logs:

\`\`\`bash
docker logs cybersec-db
\`\`\`

### Problemas con la aplicación

Si la aplicación no funciona correctamente, verifica los logs:

\`\`\`bash
docker logs cybersec-app
\`\`\`

### Reiniciar los servicios

Si necesitas reiniciar los servicios:

\`\`\`bash
docker-compose -f docker-compose.offline.yml restart
\`\`\`

### Reconstruir la aplicación

Si necesitas reconstruir la aplicación:

\`\`\`bash
docker-compose -f docker-compose.offline.yml down
docker build -t cybersec-app:offline -f Dockerfile.offline .
docker-compose -f docker-compose.offline.yml up -d
[V0_FILE]markdown:file="README.md" isFixed="true" isEdit="true" isQuickEdit="true" isMerged="true"
# CyberSec Tasks - Sistema de Gestión de Tareas de Ciberseguridad

Sistema completo para la gestión, asignación y seguimiento de tareas de ciberseguridad en organizaciones.

## Índice

- [Descripción General](#descripción-general)
- [Instalación en Entorno con Internet](#instalación-en-entorno-con-internet)
- [Instalación en Entorno sin Internet](#instalación-en-entorno-sin-internet)
  - [Preparación del Paquete Offline (Windows)](#preparación-del-paquete-offline-windows)
  - [Instalación en Linux sin Internet](#instalación-en-linux-sin-internet)
- [Características](#características)
- [Configuración](#configuración)
- [Solución de Problemas](#solución-de-problemas)
- [Mantenimiento](#mantenimiento)
- [FAQs](#faqs)
- [Licencia](#licencia)

## Descripción General

CyberSec Tasks es una aplicación web para la gestión de tareas de ciberseguridad, diseñada para ayudar a los equipos de seguridad a organizar, asignar y dar seguimiento a las tareas críticas de seguridad. La aplicación permite la categorización de tareas por nivel de riesgo, departamento, y controles CIS, facilitando así la gestión eficiente de las responsabilidades de seguridad.

## Instalación en Entorno con Internet

Si tienes conexión a internet, puedes instalar la aplicación de manera sencilla con Docker:

\`\`\`bash
# Clonar el repositorio
git clone https://github.com/tu-usuario/cybersec-tasks.git
cd cybersec-tasks

# Iniciar con Docker Compose
docker-compose up -d

# Acceder a la aplicación
# http://localhost:3000
\`\`\`

## Instalación en Entorno sin Internet

### Preparación del Paquete Offline (Windows)

Para preparar un paquete que pueda ser instalado en un entorno Linux sin conexión a internet, sigue estos pasos en un equipo Windows **con conexión a internet**:

#### Requisitos previos (Windows)

1. Windows 10/11
2. PowerShell 5.1 o superior
3. Docker Desktop instalado y ejecutándose
4. Git instalado
5. 7-Zip instalado (opcional, pero recomendado)

#### Pasos detallados

1. **Clonar el repositorio**

   Abre PowerShell y ejecuta:

   \`\`\`powershell
   git clone https://github.com/tu-usuario/cybersec-tasks.git
   cd cybersec-tasks
   \`\`\`

2. **Ejecutar el script de preparación**

   \`\`\`powershell
   .\scripts\prepare-offline-package.ps1
   \`\`\`

   Este script realizará las siguientes acciones:
   - Descargará todas las imágenes de Docker necesarias (Bitnami/Node, Bitnami/PostgreSQL)
   - Instalará todas las dependencias de Node.js
   - Construirá la aplicación
   - Guardará las imágenes Docker como archivos tar
   - Creará scripts de instalación para Linux
   - Empaquetará todo en un archivo tar.gz (o zip si 7-Zip no está disponible)

3. **Verificar el resultado**

   Al terminar, deberías tener un archivo `cybersec-tasks-offline.tar.gz` (o `cybersec-tasks-offline.zip`) en el directorio actual.

   El script mostrará información sobre el tamaño del paquete y su ubicación:

   \`\`\`
   ✅ Paquete creado exitosamente: C:\ruta\a\cybersec-tasks\cybersec-tasks-offline.tar.gz
   Tamaño: 256.7 MB
   \`\`\`

4. **Transferir el paquete a Linux**

   Transfiere el archivo `cybersec-tasks-offline.tar.gz` (o `cybersec-tasks-offline.zip`) al servidor Linux sin conexión a internet.

   Ejemplos:
   - Usando una unidad USB
   - Mediante SCP si hay conexión de red entre ambos sistemas:
     \`\`\`bash
     scp cybersec-tasks-offline.tar.gz usuario@servidor-linux:/ruta/destino/
     \`\`\`
   - A través de cualquier otro medio de transferencia de archivos

### Instalación en Linux sin Internet

Una vez que tengas el paquete en el servidor Linux sin conexión a internet, sigue estos pasos:

#### Requisitos previos (Linux)

1. Linux (Ubuntu 20.04+, Debian 11+, CentOS 8+ o distribución similar)
2. Docker instalado
3. Docker Compose instalado
4. Aproximadamente 2GB de espacio libre en disco

#### Pasos detallados

1. **Descomprimir el paquete**

   Para archivo tar.gz:
   \`\`\`bash
   tar -xzf cybersec-tasks-offline.tar.gz
   cd cybersec-tasks-offline
   \`\`\`

   Para archivo zip:
   \`\`\`bash
   unzip cybersec-tasks-offline.zip
   cd cybersec-tasks-offline
   \`\`\`

2. **Hacer ejecutables los scripts**

   \`\`\`bash
   chmod +x *.sh
   \`\`\`

3. **Ejecutar el script de instalación**

   \`\`\`bash
   ./install.sh
   \`\`\`

   Este script realizará las siguientes acciones:
   - Cargará las imágenes Docker desde los archivos tar
   - Configurará los volúmenes y permisos necesarios
   - Iniciará los contenedores con Docker Compose
   - Verificará que todo funcione correctamente

4. **Inicializar la aplicación**

   \`\`\`bash
   ./init-app.sh
   \`\`\`

   Este script:
   - Inicializará la base de datos
   - Creará datos de ejemplo (opcional)
   - Verificará la conexión entre la aplicación y la base de datos

5. **Acceder a la aplicación**

   Abre un navegador y accede a:
   \`\`\`
   http://localhost:3000
   \`\`\`

   Si accedes desde otro equipo, sustituye localhost por la dirección IP del servidor.

## Características

- Gestión completa de tareas de ciberseguridad
- Clasificación por nivel de riesgo, departamento y controles CIS
- Panel de control con estadísticas y gráficos
- Importación y exportación de datos
- Asignación de personal a tareas
- Sistema de filtros avanzados
- Funcionamiento 100% offline

## Configuración

### Cambiar el puerto de la aplicación

Edita el archivo `docker-compose.yml` y modifica el mapeo de puertos:

\`\`\`yaml
services:
  app:
    ports:
      - "8080:3000"  # Cambia 3000 por el puerto deseado
\`\`\`

Luego reinicia los contenedores:

\`\`\`bash
./restart.sh
\`\`\`

### Configurar copia de seguridad automática

El script `backup-db.sh` puede configurarse para ejecutarse periódicamente mediante cron:

\`\`\`bash
# Editar crontab
crontab -e

# Añadir una línea para hacer backup diario a las 2 AM
0 2 * * * /ruta/completa/a/cybersec-tasks-offline/backup-db.sh
\`\`\`

## Solución de Problemas

### La aplicación no carga

Verifica que los contenedores estén en ejecución:

\`\`\`bash
docker ps
\`\`\`

Si no ves los contenedores `cybersec-app` y `cybersec-db`, intenta:

\`\`\`bash
./restart.sh
\`\`\`

Revisa los logs:

\`\`\`bash
docker logs cybersec-app
docker logs cybersec-db
\`\`\`

### Error de conexión a la base de datos

Si la aplicación muestra errores de conexión a la base de datos:

1. Verifica que el contenedor de PostgreSQL esté funcionando:
   \`\`\`bash
   docker ps | grep cybersec-db
   \`\`\`

2. Reinicia los contenedores:
   \`\`\`bash
   ./restart.sh
   \`\`\`

3. Verifica los logs de PostgreSQL:
   \`\`\`bash
   docker logs cybersec-db
   \`\`\`

### Problemas de permisos

Si hay problemas de permisos con los volúmenes:

\`\`\`bash
sudo chown -R 1001:1001 ./postgres_data
sudo chmod -R 775 ./postgres_data
\`\`\`

## Mantenimiento

### Backup de la base de datos

Para crear una copia de seguridad de la base de datos:

\`\`\`bash
./backup-db.sh
\`\`\`

Esto creará un archivo en la carpeta `backups/` con el formato `backup-YYYY-MM-DD.sql`.

### Restauración de la base de datos

Para restaurar desde una copia de seguridad:

\`\`\`bash
./restore-db.sh backups/backup-2023-05-15.sql
\`\`\`

### Reinicio completo

Para reiniciar completamente la aplicación:

\`\`\`bash
./restart.sh
\`\`\`

## FAQs

### ¿Puedo usar otro sistema de base de datos?

La aplicación está configurada para usar PostgreSQL. Para usar otro sistema de base de datos, sería necesario modificar el código de la aplicación.

### ¿Cómo actualizar la aplicación?

Para actualizaciones, es recomendable generar un nuevo paquete offline siguiendo los pasos de preparación y realizar una nueva instalación.

### ¿La aplicación almacena datos sensibles?

La aplicación puede contener información sobre vulnerabilidades y tareas de seguridad. Se recomienda implementar medidas adicionales como:
- Cifrado a nivel de disco
- Control de acceso físico al servidor
- Autenticación de dos factores

## Licencia

[Incluir información de licencia]
[V0_FILE]powershell:file="scripts/prepare-offline-package.ps1" isEdit="true" isMerged="true"
# Script simplificado para preparar un paquete offline para instalación en Linux
# Los scripts de instalación ya están creados en scripts/offline/

param(
    [switch]$SkipDependencies,
    [switch]$SkipDocker,
    [switch]$SkipBuild
)

Write-Host "=== Preparando paquete offline para CyberSec Tasks ===" -ForegroundColor Green
Write-Host "Destino: Instalación en Linux sin conexión a internet" -ForegroundColor Cyan

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "package.json")) {
    Write-Host "Error: Este script debe ejecutarse desde la raíz del proyecto CyberSec Tasks" -ForegroundColor Red
    exit 1
}

# Crear directorio para el paquete
$PACKAGE_DIR = "cybersec-tasks-offline"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "`nCreando directorio del paquete..." -ForegroundColor Yellow
if (Test-Path $PACKAGE_DIR) {
    Write-Host "Eliminando paquete anterior..." -ForegroundColor Yellow
    Remove-Item -Path $PACKAGE_DIR -Recurse -Force
}
New-Item -Path $PACKAGE_DIR -ItemType Directory -Force | Out-Null

# Instalar dependencias si es necesario
if (-not $SkipDependencies) {
    if (-not (Test-Path "node_modules") -or -not (Test-Path "node_modules/react")) {
        Write-Host "`nInstalando dependencias de Node.js..." -ForegroundColor Yellow
        npm ci
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error al instalar dependencias" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "`nDependencias ya instaladas, omitiendo..." -ForegroundColor Green
    }
}

# Construir la aplicación Next.js
if (-not $SkipBuild) {
    Write-Host "`nConstruyendo la aplicación Next.js..." -ForegroundColor Yellow
    npm run build
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error al construir la aplicación" -ForegroundColor Red
        exit 1
    }
}

# Copiar archivos del proyecto
Write-Host "`nCopiando archivos del proyecto..." -ForegroundColor Yellow

# Directorios principales
$directories = @("app", "components", "lib", "public", "docs")
foreach ($dir in $directories) {
    if (Test-Path $dir) {
        Write-Host "  - Copiando $dir..." -ForegroundColor Gray
        Copy-Item -Path $dir -Destination $PACKAGE_DIR -Recurse
    }
}

# Copiar .next (aplicación construida)
if (Test-Path ".next") {
    Write-Host "  - Copiando aplicación construida (.next)..." -ForegroundColor Gray
    Copy-Item -Path ".next" -Destination $PACKAGE_DIR -Recurse
}

# Copiar node_modules
Write-Host "  - Copiando node_modules (esto puede tardar)..." -ForegroundColor Gray
Copy-Item -Path "node_modules" -Destination $PACKAGE_DIR -Recurse

# Archivos individuales
$files = @(
    "package.json",
    "package-lock.json",
    "next.config.mjs",
    "tsconfig.json",
    "tailwind.config.ts",
    "postcss.config.js",
    "init-db.sql",
    "sample-tasks.sql"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "  - Copiando $file..." -ForegroundColor Gray
        Copy-Item -Path $file -Destination $PACKAGE_DIR
    }
}

# Copiar archivos Docker
if (Test-Path "docker-compose.offline.yml") {
    Copy-Item -Path "docker-compose.offline.yml" -Destination "$PACKAGE_DIR/docker-compose.yml"
} else {
    Copy-Item -Path "docker-compose.yml" -Destination $PACKAGE_DIR
}

if (Test-Path "Dockerfile.offline") {
    Copy-Item -Path "Dockerfile.offline" -Destination "$PACKAGE_DIR/Dockerfile"
} else {
    Copy-Item -Path "Dockerfile" -Destination $PACKAGE_DIR
}

# Copiar scripts de instalación para Linux
Write-Host "`nCopiando scripts de instalación..." -ForegroundColor Yellow
$offlineScripts = @(
    "scripts/offline/install.sh",
    "scripts/offline/init-app.sh",
    "scripts/offline/restart.sh",
    "scripts/offline/backup-db.sh",
    "scripts/offline/restore-db.sh"
)

foreach ($script in $offlineScripts) {
    if (Test-Path $script) {
        $scriptName = Split-Path $script -Leaf
        Write-Host "  - Copiando $scriptName..." -ForegroundColor Gray
        Copy-Item -Path $script -Destination $PACKAGE_DIR
    }
}

# Copiar README específico para instalación offline
if (Test-Path "scripts/offline/README-OFFLINE.md") {
    Copy-Item -Path "scripts/offline/README-OFFLINE.md" -Destination "$PACKAGE_DIR/README.md"
}

# Descargar y guardar imágenes Docker
if (-not $SkipDocker) {
    Write-Host "`nDescargando imágenes Docker..." -ForegroundColor Yellow
    
    # Crear directorio para imágenes
    New-Item -Path "$PACKAGE_DIR/docker-images" -ItemType Directory -Force | Out-Null
    
    # Lista de imágenes a descargar
    $images = @(
        @{Name="bitnami/node:18"; File="node.tar"},
        @{Name="bitnami/postgresql:15"; File="postgresql.tar"}
    )
    
    foreach ($image in $images) {
        Write-Host "  - Descargando $($image.Name)..." -ForegroundColor Gray
        docker pull $image.Name
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  - Guardando $($image.Name)..." -ForegroundColor Gray
            docker save $image.Name -o "$PACKAGE_DIR/docker-images/$($image.File)"
        } else {
            Write-Host "  ! Error al descargar $($image.Name)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "`nOmitiendo descarga de imágenes Docker..." -ForegroundColor Yellow
}

# Crear archivo de información del paquete
$packageInfo = @"
CyberSec Tasks - Offline Package
================================
Fecha de creación: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Versión de Node.js: $(node --version)
Versión de npm: $(npm --version)
Sistema operativo: $($PSVersionTable.OS)

Este paquete contiene todo lo necesario para instalar
CyberSec Tasks en un entorno Linux sin conexión a internet.

Consulta README.md para instrucciones de instalación.
"@
Set-Content -Path "$PACKAGE_DIR/PACKAGE_INFO.txt" -Value $packageInfo

# Comprimir el paquete
Write-Host "`nComprimiendo el paquete..." -ForegroundColor Yellow

$outputFile = "cybersec-tasks-offline-$TIMESTAMP"

# Intentar usar 7-Zip para crear un archivo tar.gz
if (Get-Command "7z.exe" -ErrorAction SilentlyContinue) {
    Write-Host "Usando 7-Zip para crear archivo tar.gz..." -ForegroundColor Gray
    7z a -ttar "$outputFile.tar" $PACKAGE_DIR | Out-Null
    7z a -tgzip "$outputFile.tar.gz" "$outputFile.tar" | Out-Null
    Remove-Item -Path "$outputFile.tar" -Force
    $finalFile = "$outputFile.tar.gz"
} else {
    Write-Host "7-Zip no encontrado, creando archivo ZIP..." -ForegroundColor Yellow
    Compress-Archive -Path $PACKAGE_DIR -DestinationPath "$outputFile.zip" -Force
    $finalFile = "$outputFile.zip"
    Write-Host "`nNOTA: Se recomienda instalar 7-Zip para crear archivos tar.gz compatibles con Linux" -ForegroundColor Yellow
}

# Obtener información del archivo final
$fileInfo = Get-Item $finalFile
$fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)

# Mostrar resumen
Write-Host "`n=== Paquete offline creado exitosamente ===" -ForegroundColor Green
Write-Host "Archivo: $($fileInfo.Name)" -ForegroundColor Cyan
Write-Host "Tamaño: $fileSizeMB MB" -ForegroundColor Cyan
Write-Host "Ubicación: $($fileInfo.FullName)" -ForegroundColor Cyan

Write-Host "`nPara instalar en Linux sin conexión:" -ForegroundColor Yellow
Write-Host "1. Transfiere el archivo al servidor Linux" -ForegroundColor White
Write-Host "2. Descomprime el archivo:" -ForegroundColor White
if ($finalFile.EndsWith(".tar.gz")) {
    Write-Host "   tar -xzf $($fileInfo.Name)" -ForegroundColor Gray
} else {
    Write-Host "   unzip $($fileInfo.Name)" -ForegroundColor Gray
}
Write-Host "3. Navega al directorio:" -ForegroundColor White
Write-Host "   cd cybersec-tasks-offline" -ForegroundColor Gray
Write-Host "4. Ejecuta el script de instalación:" -ForegroundColor White
Write-Host "   chmod +x install.sh && ./install.sh" -ForegroundColor Gray
Write-Host "5. Inicializa la aplicación:" -ForegroundColor White
Write-Host "   chmod +x init-app.sh && ./init-app.sh" -ForegroundColor Gray

# Limpiar directorio temporal
Write-Host "`nLimpiando archivos temporales..." -ForegroundColor Yellow
Remove-Item -Path $PACKAGE_DIR -Recurse -Force

Write-Host "`n✅ Proceso completado" -ForegroundColor Green
[V0_FILE]shellscript:file="scripts/offline/install.sh" isMerged="true"
#!/bin/bash
set -e

echo "=== Instalando CyberSec Tasks en entorno Linux sin conexión ==="

# Verificar que Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "Error: Docker no está instalado. Por favor, instala Docker antes de continuar."
    exit 1
fi

# Verificar que Docker Compose está instalado
if ! command -v docker-compose &> /dev/null; then
    echo "Error: Docker Compose no está instalado. Por favor, instala Docker Compose antes de continuar."
    exit 1
fi

# Cargar imágenes Docker
echo "Cargando imágenes Docker..."
docker load < docker-images/node.tar
docker load < docker-images/postgresql.tar
docker load < docker-images/python.tar

# Construir imagen de la aplicación
echo "Construyendo imagen de la aplicación..."
docker build -t cybersec-app:offline .

# Crear directorios para volúmenes si no existen
mkdir -p ./postgres_data

# Asignar permisos adecuados a los directorios de volúmenes
# El usuario 1001 es el usuario no root que usa Bitnami en sus imágenes
echo "Configurando permisos para volúmenes..."
chmod -R 777 ./postgres_data

# Iniciar contenedores
echo "Iniciando contenedores..."
docker-compose up -d

# Esperar a que la base de datos esté lista
echo "Esperando a que la base de datos esté lista..."
sleep 10

echo "=== Instalación completada ==="
echo "La aplicación estará disponible en http://localhost:3000"
echo ""
echo "Para verificar el estado de los contenedores, ejecuta:"
echo "docker-compose ps"
echo ""
echo "Para ver los logs de la aplicación, ejecuta:"
echo "docker-compose logs -f app"
echo ""
echo "Para detener la aplicación, ejecuta:"
echo "docker-compose down"
[V0_FILE]shellscript:file="scripts/offline/init-app.sh" isMerged="true"
#!/bin/bash
set -e

echo "=== Inicializando base de datos ==="

# Esperar a que la aplicación esté lista
echo "Esperando a que la aplicación esté lista..."
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200"; then
        echo "La aplicación está lista."
        break
    fi
    echo "Intento $((attempt + 1))/$max_attempts: Esperando..."
    sleep 2
    attempt=$((attempt + 1))
done

if [ $attempt -eq $max_attempts ]; then
    echo "Error: La aplicación no respondió después de $max_attempts intentos."
    exit 1
fi

# Ejecutar la inicialización de la API
echo "Inicializando la API..."
response=$(curl -s -X POST http://localhost:3000/api/init)
echo "Respuesta: $response"

echo "=== Inicialización completada ==="
[V0_FILE]shellscript:file="scripts/offline/restart.sh" isMerged="true"
#!/bin/bash
set -e

echo "=== Reiniciando CyberSec Tasks ==="

# Detener contenedores
echo "Deteniendo contenedores..."
docker-compose down

# Iniciar contenedores
echo "Iniciando contenedores..."
docker-compose up -d

# Esperar a que la base de datos esté lista
echo "Esperando a que los servicios estén listos..."
sleep 10

echo "=== Reinicio completado ==="
echo "La aplicación estará disponible en http://localhost:3000"
[V0_FILE]shellscript:file="scripts/offline/backup-db.sh" isMerged="true"
#!/bin/bash
set -e

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/cybersec_db_${TIMESTAMP}.sql"

echo "=== Creando backup de la base de datos ==="

# Crear directorio de backups si no existe
mkdir -p $BACKUP_DIR

# Ejecutar backup
echo "Ejecutando backup..."
docker-compose exec -T db pg_dump -U cybersec_user cybersec_tasks > $BACKUP_FILE

echo "=== Backup completado ==="
echo "Archivo de backup: $BACKUP_FILE"
echo "Tamaño: $(du -h $BACKUP_FILE | cut -f1)"
[V0_FILE]shellscript:file="scripts/offline/restore-db.sh" isMerged="true"
#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Error: Debes especificar el archivo de backup a restaurar."
    echo "Uso: ./restore-db.sh ./backups/nombre_del_backup.sql"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: El archivo de backup no existe: $BACKUP_FILE"
    exit 1
fi

echo "=== Restaurando base de datos desde $BACKUP_FILE ==="

# Detener la aplicación temporalmente
echo "Deteniendo la aplicación..."
docker-compose stop app

# Restaurar backup
echo "Ejecutando restauración..."
docker-compose exec -T db psql -U cybersec_user -d cybersec_tasks -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
cat $BACKUP_FILE | docker-compose exec -T db psql -U cybersec_user -d cybersec_tasks

# Reiniciar la aplicación
echo "Reiniciando la aplicación..."
docker-compose start app

echo "=== Restauración completada ==="
[V0_FILE]markdown:file="scripts/offline/README-OFFLINE.md" isMerged="true"
# CyberSec Tasks - Instalación sin conexión a internet

Esta es una versión empaquetada de CyberSec Tasks que puede instalarse en un entorno Linux sin conexión a internet.

## Requisitos

- Docker (versión 20.10.0 o superior)
- Docker Compose (versión 2.0.0 o superior)
- Bash
- curl (para inicialización)
- Al menos 2GB de espacio libre en disco

## Contenido del paquete

Este paquete incluye:
- Aplicación CyberSec Tasks completa
- Todas las dependencias de Node.js (node_modules)
- Imágenes Docker necesarias (Bitnami Node.js, PostgreSQL)
- Scripts de instalación y gestión
- Base de datos PostgreSQL preconfigurada

## Instalación

### 1. Verificar requisitos

Asegúrate de que Docker y Docker Compose estén instalados:

\`\`\`bash
docker --version
docker-compose --version
\`\`\`

### 2. Ejecutar el script de instalación

\`\`\`bash
chmod +x install.sh
./install.sh
\`\`\`

Este script:
- Carga las imágenes Docker incluidas
- Construye la imagen de la aplicación
- Configura los volúmenes necesarios
- Inicia todos los servicios

### 3. Inicializar la aplicación

Una vez que los contenedores estén en funcionamiento:

\`\`\`bash
chmod +x init-app.sh
./init-app.sh
\`\`\`

Este script:
- Espera a que la aplicación esté lista
- Inicializa la base de datos
- Carga datos de ejemplo

### 4. Acceder a la aplicación

Abre tu navegador y accede a:
- http://localhost:3000

Si accedes desde otro equipo, reemplaza `localhost` con la dirección IP del servidor.

## Scripts incluidos

### install.sh
Instala y ejecuta la aplicación por primera vez.

### init-app.sh
Inicializa la base de datos y carga datos de ejemplo.

### restart.sh
Reinicia todos los contenedores de la aplicación.

### backup-db.sh
Crea una copia de seguridad de la base de datos.

\`\`\`bash
chmod +x backup-db.sh
./backup-db.sh
\`\`\`

Los backups se guardan en la carpeta `backups/` con el formato `cybersec_db_YYYYMMDD_HHMMSS.sql`.

### restore-db.sh
Restaura la base de datos desde una copia de seguridad.

\`\`\`bash
chmod +x restore-db.sh
./restore-db.sh ./backups/cybersec_db_20231215_143022.sql
\`\`\`

## Gestión de la aplicación

### Ver el estado de los contenedores
\`\`\`bash
docker-compose ps
\`\`\`

### Ver logs de la aplicación
\`\`\`bash
docker-compose logs -f app
\`\`\`

### Ver logs de la base de datos
\`\`\`bash
docker-compose logs -f db
\`\`\`

### Detener la aplicación
\`\`\`bash
docker-compose down
\`\`\`

### Detener y eliminar todos los datos
\`\`\`bash
docker-compose down -v
rm -rf ./postgres_data
\`\`\`

## Configuración

### Cambiar el puerto de la aplicación

Edita el archivo `docker-compose.yml` y modifica la línea del puerto:

\`\`\`yaml
services:
  app:
    ports:
      - "8080:3000"  # Cambia 8080 por el puerto deseado
\`\`\`

Luego reinicia la aplicación:
\`\`\`bash
./restart.sh
\`\`\`

### Variables de entorno

Las variables de entorno están configuradas en `docker-compose.yml`. Las principales son:

- `DATABASE_URL`: URL de conexión a PostgreSQL
- `NODE_ENV`: Entorno de ejecución (production)
- `PORT`: Puerto interno de la aplicación (3000)

## Solución de problemas

### La aplicación no se inicia

1. Verifica que los contenedores estén en ejecución:
   \`\`\`bash
   docker ps
   \`\`\`

2. Revisa los logs de la aplicación:
   \`\`\`bash
   docker-compose logs app
   \`\`\`

3. Revisa los logs de la base de datos:
   \`\`\`bash
   docker-compose logs db
   \`\`\`

### Error de conexión a la base de datos

1. Verifica que el contenedor de PostgreSQL esté funcionando:
   \`\`\`bash
   docker ps | grep db
   \`\`\`

2. Intenta reiniciar los servicios:
   \`\`\`bash
   ./restart.sh
   \`\`\`

### Problemas de permisos

Si hay problemas con los volúmenes de Docker:

\`\`\`bash
sudo chown -R 1001:1001 ./postgres_data
sudo chmod -R 775 ./postgres_data
\`\`\`

### La aplicación responde lentamente

1. Verifica los recursos del sistema:
   \`\`\`bash
   docker stats
   \`\`\`

2. Asigna más recursos a Docker si es necesario.

### Reiniciar desde cero

Si necesitas empezar de nuevo:

\`\`\`bash
# Detener y eliminar todo
docker-compose down -v
rm -rf ./postgres_data

# Reinstalar
./install.sh
./init-app.sh
\`\`\`

## Mantenimiento

### Backup automático

Para configurar backups automáticos con cron:

\`\`\`bash
# Editar crontab
crontab -e

# Añadir línea para backup diario a las 2:00 AM
0 2 * * * /ruta/completa/a/backup-db.sh
\`\`\`

### Monitoreo

Para monitorear el uso de recursos:

\`\`\`bash
# Ver uso de CPU y memoria
docker stats

# Ver espacio en disco
df -h
docker system df
\`\`\`

### Limpieza

Para liberar espacio:

\`\`\`bash
# Eliminar imágenes no utilizadas
docker image prune -a

# Eliminar volúmenes no utilizados
docker volume prune

# Limpieza completa (¡cuidado!)
docker system prune -a
\`\`\`

## Seguridad

### Recomendaciones

1. **Firewall**: Configura el firewall para permitir solo el acceso necesario
2. **HTTPS**: Considera usar un proxy reverso con SSL (nginx, traefik)
3. **Backups**: Realiza backups regulares de la base de datos
4. **Actualizaciones**: Mantén Docker y el sistema operativo actualizados

### Acceso a la base de datos

La base de datos solo es accesible desde los contenedores Docker. Para acceder directamente:

\`\`\`bash
docker-compose exec db psql -U cybersec_user -d cybersec_tasks
\`\`\`

## Soporte

Si encuentras problemas:

1. Revisa esta documentación
2. Consulta los logs de la aplicación
3. Verifica la configuración de Docker
4. Contacta al equipo de soporte con los logs relevantes
\`\`\`

Ahora, vamos a simplificar el script PowerShell para que solo empaquete los archivos:

```powershell file="scripts/prepare-offline-package.ps1"
# Script simplificado para preparar un paquete offline para instalación en Linux
# Los scripts de instalación ya están creados en scripts/offline/

param(
    [switch]$SkipDependencies,
    [switch]$SkipDocker,
    [switch]$SkipBuild
)

Write-Host "=== Preparando paquete offline para CyberSec Tasks ===" -ForegroundColor Green
Write-Host "Destino: Instalación en Linux sin conexión a internet" -ForegroundColor Cyan

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "package.json")) {
    Write-Host "Error: Este script debe ejecutarse desde la raíz del proyecto CyberSec Tasks" -ForegroundColor Red
    exit 1
}

# Crear directorio para el paquete
$PACKAGE_DIR = "cybersec-tasks-offline"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "`nCreando directorio del paquete..." -ForegroundColor Yellow
if (Test-Path $PACKAGE_DIR) {
    Write-Host "Eliminando paquete anterior..." -ForegroundColor Yellow
    Remove-Item -Path $PACKAGE_DIR -Recurse -Force
}
New-Item -Path $PACKAGE_DIR -ItemType Directory -Force | Out-Null

# Instalar dependencias si es necesario
if (-not $SkipDependencies) {
    if (-not (Test-Path "node_modules") -or -not (Test-Path "node_modules/react")) {
        Write-Host "`nInstalando dependencias de Node.js..." -ForegroundColor Yellow
        npm ci
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error al instalar dependencias" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "`nDependencias ya instaladas, omitiendo..." -ForegroundColor Green
    }
}

# Construir la aplicación Next.js
if (-not $SkipBuild) {
    Write-Host "`nConstruyendo la aplicación Next.js..." -ForegroundColor Yellow
    npm run build
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error al construir la aplicación" -ForegroundColor Red
        exit 1
    }
}

# Copiar archivos del proyecto
Write-Host "`nCopiando archivos del proyecto..." -ForegroundColor Yellow

# Directorios principales
$directories = @("app", "components", "lib", "public", "docs")
foreach ($dir in $directories) {
    if (Test-Path $dir) {
        Write-Host "  - Copiando $dir..." -ForegroundColor Gray
        Copy-Item -Path $dir -Destination $PACKAGE_DIR -Recurse
    }
}

# Copiar .next (aplicación construida)
if (Test-Path ".next") {
    Write-Host "  - Copiando aplicación construida (.next)..." -ForegroundColor Gray
    Copy-Item -Path ".next" -Destination $PACKAGE_DIR -Recurse
}

# Copiar node_modules
Write-Host "  - Copiando node_modules (esto puede tardar)..." -ForegroundColor Gray
Copy-Item -Path "node_modules" -Destination $PACKAGE_DIR -Recurse

# Archivos individuales
$files = @(
    "package.json",
    "package-lock.json",
    "next.config.mjs",
    "tsconfig.json",
    "tailwind.config.ts",
    "postcss.config.js",
    "init-db.sql",
    "sample-tasks.sql"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "  - Copiando $file..." -ForegroundColor Gray
        Copy-Item -Path $file -Destination $PACKAGE_DIR
    }
}

# Copiar archivos Docker
if (Test-Path "docker-compose.offline.yml") {
    Copy-Item -Path "docker-compose.offline.yml" -Destination "$PACKAGE_DIR/docker-compose.yml"
} else {
    Copy-Item -Path "docker-compose.yml" -Destination $PACKAGE_DIR
}

if (Test-Path "Dockerfile.offline") {
    Copy-Item -Path "Dockerfile.offline" -Destination "$PACKAGE_DIR/Dockerfile"
} else {
    Copy-Item -Path "Dockerfile" -Destination $PACKAGE_DIR
}

# Copiar scripts de instalación para Linux
Write-Host "`nCopiando scripts de instalación..." -ForegroundColor Yellow
$offlineScripts = @(
    "scripts/offline/install.sh",
    "scripts/offline/init-app.sh",
    "scripts/offline/restart.sh",
    "scripts/offline/backup-db.sh",
    "scripts/offline/restore-db.sh"
)

foreach ($script in $offlineScripts) {
    if (Test-Path $script) {
        $scriptName = Split-Path $script -Leaf
        Write-Host "  - Copiando $scriptName..." -ForegroundColor Gray
        Copy-Item -Path $script -Destination $PACKAGE_DIR
    }
}

# Copiar README específico para instalación offline
if (Test-Path "scripts/offline/README-OFFLINE.md") {
    Copy-Item -Path "scripts/offline/README-OFFLINE.md" -Destination "$PACKAGE_DIR/README.md"
}

# Descargar y guardar imágenes Docker
if (-not $SkipDocker) {
    Write-Host "`nDescargando imágenes Docker..." -ForegroundColor Yellow
    
    # Crear directorio para imágenes
    New-Item -Path "$PACKAGE_DIR/docker-images" -ItemType Directory -Force | Out-Null
    
    # Lista de imágenes a descargar
    $images = @(
        @{Name="bitnami/node:18"; File="node.tar"},
        @{Name="bitnami/postgresql:15"; File="postgresql.tar"}
    )
    
    foreach ($image in $images) {
        Write-Host "  - Descargando $($image.Name)..." -ForegroundColor Gray
        docker pull $image.Name
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  - Guardando $($image.Name)..." -ForegroundColor Gray
            docker save $image.Name -o "$PACKAGE_DIR/docker-images/$($image.File)"
        } else {
            Write-Host "  ! Error al descargar $($image.Name)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "`nOmitiendo descarga de imágenes Docker..." -ForegroundColor Yellow
}

# Crear archivo de información del paquete
$packageInfo = @"
CyberSec Tasks - Offline Package
================================
Fecha de creación: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Versión de Node.js: $(node --version)
Versión de npm: $(npm --version)
Sistema operativo: $($PSVersionTable.OS)

Este paquete contiene todo lo necesario para instalar
CyberSec Tasks en un entorno Linux sin conexión a internet.

Consulta README.md para instrucciones de instalación.
"@
Set-Content -Path "$PACKAGE_DIR/PACKAGE_INFO.txt" -Value $packageInfo

# Comprimir el paquete
Write-Host "`nComprimiendo el paquete..." -ForegroundColor Yellow

$outputFile = "cybersec-tasks-offline-$TIMESTAMP"

# Intentar usar 7-Zip para crear un archivo tar.gz
if (Get-Command "7z.exe" -ErrorAction SilentlyContinue) {
    Write-Host "Usando 7-Zip para crear archivo tar.gz..." -ForegroundColor Gray
    7z a -ttar "$outputFile.tar" $PACKAGE_DIR | Out-Null
    7z a -tgzip "$outputFile.tar.gz" "$outputFile.tar" | Out-Null
    Remove-Item -Path "$outputFile.tar" -Force
    $finalFile = "$outputFile.tar.gz"
} else {
    Write-Host "7-Zip no encontrado, creando archivo ZIP..." -ForegroundColor Yellow
    Compress-Archive -Path $PACKAGE_DIR -DestinationPath "$outputFile.zip" -Force
    $finalFile = "$outputFile.zip"
    Write-Host "`nNOTA: Se recomienda instalar 7-Zip para crear archivos tar.gz compatibles con Linux" -ForegroundColor Yellow
}

# Obtener información del archivo final
$fileInfo = Get-Item $finalFile
$fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)

# Mostrar resumen
Write-Host "`n=== Paquete offline creado exitosamente ===" -ForegroundColor Green
Write-Host "Archivo: $($fileInfo.Name)" -ForegroundColor Cyan
Write-Host "Tamaño: $fileSizeMB MB" -ForegroundColor Cyan
Write-Host "Ubicación: $($fileInfo.FullName)" -ForegroundColor Cyan

Write-Host "`nPara instalar en Linux sin conexión:" -ForegroundColor Yellow
Write-Host "1. Transfiere el archivo al servidor Linux" -ForegroundColor White
Write-Host "2. Descomprime el archivo:" -ForegroundColor White
if ($finalFile.EndsWith(".tar.gz")) {
    Write-Host "   tar -xzf $($fileInfo.Name)" -ForegroundColor Gray
} else {
    Write-Host "   unzip $($fileInfo.Name)" -ForegroundColor Gray
}
Write-Host "3. Navega al directorio:" -ForegroundColor White
Write-Host "   cd cybersec-tasks-offline" -ForegroundColor Gray
Write-Host "4. Ejecuta el script de instalación:" -ForegroundColor White
Write-Host "   chmod +x install.sh && ./install.sh" -ForegroundColor Gray
Write-Host "5. Inicializa la aplicación:" -ForegroundColor White
Write-Host "   chmod +x init-app.sh && ./init-app.sh" -ForegroundColor Gray

# Limpiar directorio temporal
Write-Host "`nLimpiando archivos temporales..." -ForegroundColor Yellow
Remove-Item -Path $PACKAGE_DIR -Recurse -Force

Write-Host "`n✅ Proceso completado" -ForegroundColor Green
